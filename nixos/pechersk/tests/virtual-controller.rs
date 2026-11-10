//! Root-only integration fixture. Models the audited Atari button/axis layout.
//! Commands: a, b, start, back, guide-down/up, start-down/up, a-down/up,
//! stick-left/center/right, directions, quit.
use std::{fs::OpenOptions, io::{self, BufRead, Write}, os::fd::AsRawFd, thread, time::Duration};

unsafe extern "C" { fn ioctl(fd: i32, request: u64, ...) -> i32; }
#[repr(C)]
#[derive(Default)]
struct InputId { bus: u16, vendor: u16, product: u16, version: u16 }
#[repr(C)]
struct Device { name: [u8; 80], id: InputId, ff: u32, max: [i32; 64], min: [i32; 64], fuzz: [i32; 64], flat: [i32; 64] }
#[repr(C)]
struct Event { seconds: i64, micros: i64, kind: u16, code: u16, value: i32 }
fn bytes<T>(value: &T) -> &[u8] {
    // These repr(C) records contain initialized scalar fields and no padding.
    unsafe { std::slice::from_raw_parts((value as *const T).cast(), std::mem::size_of::<T>()) }
}
fn main() -> io::Result<()> {
    let mut file = OpenOptions::new().write(true).open("/dev/uinput")?;
    let fd = file.as_raw_fd();
    for kind in [0_i32, 1, 3] { if unsafe { ioctl(fd, 0x40045564, kind) } < 0 { return Err(io::Error::last_os_error()); } }
    for key in [139_i32, 158, 172, 256, 304, 305, 307, 308, 310, 311, 317, 318] {
        if unsafe { ioctl(fd, 0x40045565, key) } < 0 { return Err(io::Error::last_os_error()); }
    }
    let mut device = Device { name: [0; 80], id: InputId {bus: 5, vendor: 0x3250, product: 0x1002, version: 0x139}, ff: 0, max: [0;64], min: [0;64], fuzz: [0;64], flat: [0;64] };
    device.name[..15].copy_from_slice(b"Game Controller");
    for axis in [0_usize, 1, 2, 5, 9, 10, 16, 17] {
        if unsafe { ioctl(fd, 0x40045567, axis as i32) } < 0 { return Err(io::Error::last_os_error()); }
        device.min[axis] = if axis >= 16 {-1} else if axis >= 9 {0} else {-32768};
        device.max[axis] = if axis >= 16 {1} else if axis >= 9 {255} else {32767};
        device.flat[axis] = if axis < 9 {128} else {0};
    }
    assert_eq!(std::mem::size_of::<Device>(), 1116);
    assert_eq!(std::mem::size_of::<Event>(), 24);
    file.write_all(bytes(&device))?;
    if unsafe { ioctl(fd, 0x5501) } < 0 { return Err(io::Error::last_os_error()); }
    println!("Virtual Atari controller created; enter commands, or quit to remove it.");
    for line in io::stdin().lock().lines() {
        let line = line?;
        if matches!(line.trim(), "stick-left" | "stick-center" | "stick-right") {
            let value = match line.trim() { "stick-left" => -16000, "stick-right" => 16000, _ => 0 };
            file.write_all(bytes(&Event {seconds: 0, micros: 0, kind: 3, code: 0, value}))?;
            file.write_all(bytes(&Event {seconds: 0, micros: 0, kind: 0, code: 0, value: 0}))?;
            continue;
        }
        if matches!(line.trim(), "guide-down" | "guide-up" | "start-down" | "start-up" | "a-down" | "a-up") {
            let value = i32::from(line.trim().ends_with("-down"));
            let code = if line.trim().starts_with("guide-") {172} else if line.trim().starts_with("a-") {304} else {139};
            file.write_all(bytes(&Event {seconds: 0, micros: 0, kind: 1, code, value}))?;
            file.write_all(bytes(&Event {seconds: 0, micros: 0, kind: 0, code: 0, value: 0}))?;
            continue;
        }
        let (kind, code, value) = match line.trim() {
            "a" => (1, 304, 1), "b" => (1, 305, 1), "start" => (1, 139, 1), "back" => (1, 158, 1),
            "up" => (3, 17, -1), "down" => (3, 17, 1), "left" => (3, 16, -1), "right" => (3, 16, 1),
            "quit" => break, _ => {println!("Unknown command"); continue;}
        };
        for state in [value, 0] {
            file.write_all(bytes(&Event {seconds: 0, micros: 0, kind, code, value: state}))?;
            file.write_all(bytes(&Event {seconds: 0, micros: 0, kind: 0, code: 0, value: 0}))?;
            thread::sleep(Duration::from_millis(150));
        }
        println!("Sent {line}");
    }
    if unsafe { ioctl(fd, 0x5502) } < 0 { return Err(io::Error::last_os_error()); }
    Ok(())
}
