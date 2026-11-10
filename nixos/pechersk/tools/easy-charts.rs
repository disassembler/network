//! One-shot, dependency-free StepMania library audit and additive chart authoring.
use std::{
    collections::BTreeMap,
    env, fs,
    path::{Path, PathBuf},
};
#[derive(Clone, Debug)]
struct Tag {
    key: String,
    value: String,
}
fn clean(s: &str) -> String {
    s.lines()
        .map(|l| l.split("//").next().unwrap_or(""))
        .collect::<Vec<_>>()
        .join("\n")
}
fn tags(s: &str) -> Vec<Tag> {
    let s = clean(s);
    let mut out = vec![];
    let mut remaining = s.as_str();
    while let Some(hash) = remaining.find('#') {
        remaining = &remaining[hash + 1..];
        let Some(colon) = remaining.find(':') else {
            break;
        };
        let end = remaining[colon + 1..]
            .find(';')
            .map(|n| n + colon + 1)
            .unwrap_or(remaining.len());
        out.push(Tag {
            key: remaining[..colon].trim().to_uppercase(),
            value: remaining[colon + 1..end].trim().to_string(),
        });
        remaining = remaining.get(end + 1..).unwrap_or("");
    }
    out
}
fn get<'a>(t: &'a [Tag], key: &str) -> &'a str {
    t.iter()
        .find(|t| t.key == key)
        .map(|t| t.value.as_str())
        .unwrap_or("")
}
#[derive(Clone)]
struct Chart {
    single: bool,
    difficulty: String,
    meter: u32,
    notes: String,
    timing: Vec<Tag>,
}
fn charts(t: &[Tag], ssc: bool) -> Vec<Chart> {
    let mut result = vec![];
    if t.iter().any(|t| t.key == "SINGLE") {
        for tag in t.iter().filter(|t| t.key == "SINGLE") {
            let p: Vec<_> = tag.value.splitn(3, ':').collect();
            if p.len() != 3 {
                continue;
            }
            if let Ok(notes) = dwi_notes(p[2]) {
                let difficulty = match p[0].trim().to_uppercase().as_str() {
                    "BASIC" | "LIGHT" | "EASY" => "Easy",
                    "ANOTHER" | "TRICK" => "Medium",
                    "MANIAC" | "HEAVY" => "Hard",
                    "SMANIAC" | "ONI" => "Challenge",
                    "BEGINNER" => "Beginner",
                    _ => "Edit",
                };
                result.push(Chart {
                    single: true,
                    difficulty: difficulty.into(),
                    meter: p[1].trim().parse().unwrap_or(99),
                    notes,
                    timing: vec![],
                });
            }
        }
    } else if ssc {
        for block in t.split(|t| t.key == "NOTEDATA").skip(1) {
            if ["dance-single", "dance-couple", "dance-double"].contains(&get(block, "STEPSTYPE")) {
                result.push(Chart {
                    single: get(block, "STEPSTYPE") == "dance-single",
                    difficulty: get(block, "DIFFICULTY").to_string(),
                    meter: get(block, "METER").parse().unwrap_or(99),
                    notes: get(block, "NOTES").to_string(),
                    timing: block
                        .iter()
                        .filter(|t| TIMING.contains(&t.key.as_str()))
                        .cloned()
                        .collect(),
                });
            }
        }
    } else {
        for tag in t.iter().filter(|t| t.key == "NOTES") {
            let p: Vec<_> = tag.value.splitn(6, ':').collect();
            if p.len() == 6
                && ["dance-single", "dance-couple", "dance-double"].contains(&p[0].trim())
            {
                result.push(Chart {
                    single: p[0].trim() == "dance-single",
                    difficulty: p[2].trim().into(),
                    meter: p[3].trim().parse().unwrap_or(99),
                    notes: p[5].into(),
                    timing: vec![],
                });
            }
        }
    }
    result
}
const TIMING: &[&str] = &[
    "BPMS",
    "STOPS",
    "DELAYS",
    "WARPS",
    "FAKES",
    "TIMESIGNATURES",
    "TICKCOUNTS",
    "COMBOS",
    "SPEEDS",
    "SCROLLS",
    "OFFSET",
];
// DWI eighth-note tokens and grouped subdivisions, matching NotesLoaderDWI.
fn dwi_notes(data: &str) -> Result<String, String> {
    let chars: Vec<_> = data.chars().filter(|c| !c.is_whitespace()).collect();
    let mut events = BTreeMap::new();
    let mut tick = 0usize;
    let mut increment = 24;
    let mut i = 0;
    while i < chars.len() {
        let c = chars[i];
        i += 1;
        match c {
            '(' => increment = 12,
            '[' => increment = 8,
            '{' => increment = 3,
            '`' => increment = 1,
            ')' | ']' | '}' | '\'' | '>' => increment = 24,
            '<' => return Err("manual review: legacy DWI angle group".into()),
            '0'..='9' | 'A' | 'B' => {
                let columns: &[usize] = match c {
                    '1' => &[0, 1],
                    '2' => &[1],
                    '3' => &[1, 3],
                    '4' => &[0],
                    '6' => &[3],
                    '7' => &[0, 2],
                    '8' => &[2],
                    '9' => &[2, 3],
                    'A' => &[1, 2],
                    'B' => &[0, 3],
                    _ => &[],
                };
                let mut row = ['0'; 4];
                for col in columns {
                    row[*col] = '1'
                }
                if i < chars.len() && chars[i] == '!' {
                    i += 2;
                    for col in columns {
                        row[*col] = '2'
                    }
                }
                if !columns.is_empty() {
                    events.insert(tick, row.iter().collect::<String>());
                }
                tick += increment;
            }
            _ => return Err(format!("manual review: DWI token {c}")),
        }
    }
    let measures = tick.div_ceil(192);
    Ok((0..measures)
        .map(|m| {
            (0..192)
                .map(|r| {
                    events
                        .get(&(m * 192 + r))
                        .cloned()
                        .unwrap_or_else(|| "0000".into())
                })
                .collect::<Vec<_>>()
                .join("\n")
        })
        .collect::<Vec<_>>()
        .join("\n,\n"))
}
fn pairs(s: &str) -> Vec<(f64, f64)> {
    let mut v: Vec<_> = s
        .split(',')
        .filter_map(|p| {
            let mut p = p.trim().split('=');
            Some((
                p.next()?.trim().parse().ok()?,
                p.next()?.trim().parse().ok()?,
            ))
        })
        .collect();
    v.sort_by(|a, b| f64::total_cmp(&a.0, &b.0));
    v
}
struct Clock {
    bpm: Vec<(f64, f64)>,
    pauses: Vec<(f64, f64)>,
}
impl Clock {
    fn new(global: &[Tag], chart: &Chart) -> Result<Self, String> {
        let value = |key| {
            let v = get(&chart.timing, key);
            if v.is_empty() { get(global, key) } else { v }
        };
        for k in ["WARPS", "FAKES"] {
            if pairs(value(k)).iter().any(|p| p.1.abs() > 0.00001) {
                return Err(format!("manual review: {k}"));
            }
        }
        let mut bpm = pairs(value("BPMS"));
        if bpm.is_empty() && !get(global, "BPM").is_empty() {
            bpm.push((
                0.0,
                get(global, "BPM").parse().map_err(|_| "invalid DWI BPM")?,
            ));
            bpm.extend(
                pairs(get(global, "CHANGEBPM"))
                    .into_iter()
                    .chain(pairs(get(global, "BPMCHANGE")))
                    .map(|(b, v)| (b / 4.0, v)),
            );
            bpm.sort_by(|a, b| a.0.total_cmp(&b.0));
        }
        if bpm.is_empty() || bpm.iter().any(|p| !p.1.is_finite() || p.1 <= 0.0) {
            return Err("manual review: invalid/negative BPM".into());
        }
        let pauses: Vec<_> = pairs(value("STOPS"))
            .into_iter()
            .chain(pairs(value("DELAYS")))
            .chain(
                pairs(get(global, "FREEZE"))
                    .into_iter()
                    .map(|(b, v)| (b / 4.0, v / 1000.0)),
            )
            .collect();
        if pauses.iter().any(|p| p.1 < 0.0 || !p.1.is_finite()) {
            return Err("manual review: negative stop".into());
        }
        Ok(Self { bpm, pauses })
    }
    fn time(&self, beat: f64) -> f64 {
        let mut time = 0.0;
        let mut prev = 0.0;
        let mut bpm = self.bpm[0].1;
        for &(b, v) in &self.bpm {
            if b <= 0.0 {
                bpm = v;
                continue;
            }
            if b >= beat {
                break;
            }
            time += (b - prev) * 60.0 / bpm;
            prev = b;
            bpm = v;
        }
        time += (beat - prev) * 60.0 / bpm;
        time + self
            .pauses
            .iter()
            .filter(|p| p.0 < beat)
            .map(|p| p.1)
            .sum::<f64>()
    }
    fn bpm_at(&self, b: f64) -> f64 {
        self.bpm
            .iter()
            .rev()
            .find(|p| p.0 <= b)
            .unwrap_or(&self.bpm[0])
            .1
    }
}
#[derive(Default)]
struct Stats {
    events: usize,
    jumps: usize,
    holds: usize,
    mines: usize,
    min_gap: f64,
    rate: f64,
}
fn rows(notes: &str) -> Vec<(f64, String)> {
    notes
        .split(',')
        .enumerate()
        .flat_map(|(m, measure)| {
            let rows: Vec<_> = measure
                .lines()
                .map(str::trim)
                .filter(|s| !s.is_empty())
                .collect();
            let n = rows.len() as f64;
            rows.into_iter()
                .enumerate()
                .map(move |(r, s)| (m as f64 * 4.0 + r as f64 * 4.0 / n, s.to_string()))
        })
        .collect()
}
fn stats(c: &Chart, clock: &Clock) -> Stats {
    let mut s = Stats {
        min_gap: f64::INFINITY,
        ..Default::default()
    };
    let mut times = vec![];
    for (beat, row) in rows(&c.notes) {
        let heads = row.chars().filter(|c| matches!(c, '1' | '2' | '4')).count();
        s.mines += row.matches('M').count();
        s.holds += row.matches(['2', '4']).count();
        if heads > 0 {
            s.events += 1;
            s.jumps += usize::from(heads > 1);
            times.push(clock.time(beat));
        }
    }
    for w in times.windows(2) {
        s.min_gap = s.min_gap.min(w[1] - w[0]);
    }
    if times.len() > 1 {
        s.rate = (times.len() - 1) as f64 / (times.last().unwrap() - times[0]).max(1.0)
    }
    s
}
fn gentle(s: &Stats, meter: u32, beginner: bool) -> bool {
    s.events >= 12
        && meter <= if beginner { 2 } else { 4 }
        && s.rate <= if beginner { 0.85 } else { 1.5 }
        && s.min_gap >= if beginner { 0.65 } else { 0.35 }
        && s.mines == 0
        && (if beginner {
            s.jumps == 0
        } else {
            s.jumps * 100 <= s.events * 15
        })
}
fn generate(source: &Chart, clock: &Clock, beginner: bool) -> Result<Chart, String> {
    let original = rows(&source.notes);
    let mut selected = BTreeMap::new();
    let mut last = -1000.0;
    let mut count = 0;
    let stride_at = |beat: f64| {
        let bpm = clock.bpm_at(beat);
        if beginner {
            if bpm > 200.0 {
                8
            } else if bpm > 110.0 {
                4
            } else {
                2
            }
        } else if bpm > 200.0 {
            4
        } else {
            2
        }
    };
    let phase_count = |phase: i64| {
        original
            .iter()
            .filter(|(b, r)| {
                (*b - b.round()).abs() < 0.0001
                    && (b.round() as i64 - phase).rem_euclid(stride_at(*b)) == 0
                    && r.chars().any(|c| matches!(c, '1' | '2' | '4'))
            })
            .count()
    };
    let phase = if phase_count(0) < 16 {
        (0..8).max_by_key(|p| phase_count(*p)).unwrap_or(0)
    } else {
        0
    };
    // Repeated patterns alternate feet and keep the centre arrows sparse.
    let pattern: &[usize] = if beginner {
        &[0, 3, 0, 3, 1, 3, 0, 3, 0, 2, 0, 3, 1, 3, 0, 3]
    } else {
        &[0, 3, 1, 3, 0, 2, 0, 3, 1, 3, 0, 2, 0, 3, 1, 3]
    };
    for (beat, row) in &original {
        if !row.chars().any(|c| matches!(c, '1' | '2' | '4'))
            || (*beat - beat.round()).abs() > 0.0001
        {
            continue;
        }
        let b = beat.round() as i64;
        // Half/whole notes on the source grid; scale down fast songs further.
        let stride = stride_at(*beat);
        if (b - phase).rem_euclid(stride) != 0 || b.rem_euclid(32) >= if beginner { 28 } else { 30 }
        {
            continue;
        }
        let time = clock.time(*beat);
        if time - last < if beginner { 0.85 } else { 0.55 } {
            continue;
        }
        let mut row = ['0'; 4];
        row[pattern[count % pattern.len()]] = '1';
        selected.insert(b, row.iter().collect::<String>());
        last = time;
        count += 1;
    }
    if count < 12 {
        return Err("manual review: too few strong-beat source notes".into());
    }
    let mut measures = vec![];
    for m in 0..source.notes.split(',').count() {
        let mut r = vec![];
        for b in 0..4 {
            r.push(
                selected
                    .get(&((m * 4 + b) as i64))
                    .cloned()
                    .unwrap_or_else(|| "0000".into()),
            );
        }
        measures.push(r.join("\n"));
    }
    Ok(Chart {
        single: true,
        difficulty: if beginner { "Beginner" } else { "Easy" }.into(),
        meter: if beginner { 1 } else { 3 },
        notes: measures.join("\n,\n"),
        timing: source.timing.clone(),
    })
}
fn render(c: &Chart, ssc: bool, dwi: bool, description: &str) -> String {
    if dwi {
        let notes = rows(&c.notes)
            .into_iter()
            .map(|(_, r)| {
                let digit = match r.find('1') {
                    Some(0) => '4',
                    Some(1) => '2',
                    Some(2) => '8',
                    Some(3) => '6',
                    _ => '0',
                };
                format!("{digit}0")
            })
            .collect::<String>();
        format!(
            "\n// Pechersk accessible addition v1: {description}\n#SINGLE:{}:{}:{notes};\n",
            c.difficulty.to_uppercase(),
            c.meter
        )
    } else if ssc {
        let timing = c
            .timing
            .iter()
            .map(|t| format!("#{}:{};\n", t.key, t.value))
            .collect::<String>();
        format!(
            "\n// Pechersk accessible addition v1; original charts preserved\n#NOTEDATA:;\n#CHARTNAME:{description};\n#STEPSTYPE:dance-single;\n#DESCRIPTION:{description};\n#DIFFICULTY:{};\n#METER:{};\n#RADARVALUES:0,0,0,0,0;\n#CREDIT:Pechersk family charts;\n{timing}#NOTES:\n{}\n;\n",
            c.difficulty, c.meter, c.notes
        )
    } else {
        format!(
            "\n// Pechersk accessible addition v1; original charts preserved\n#NOTES:\ndance-single:\n{description}:\n{}:\n{}:\n0,0,0,0,0:\n{}\n;\n",
            c.difficulty, c.meter, c.notes
        )
    }
}
fn walk(p: &Path, files: &mut Vec<PathBuf>) -> std::io::Result<()> {
    for e in fs::read_dir(p)? {
        let e = e?;
        if e.file_type()?.is_dir() {
            walk(&e.path(), files)?
        } else if e.file_type()?.is_file() {
            files.push(e.path());
        }
    }
    Ok(())
}
fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<_> = env::args().collect();
    if args.len() == 3 && args[1] == "sidecars" {
        let path = Path::new(&args[2]);
        let text = fs::read_to_string(path)?;
        let t = tags(&text);
        for block in t.split(|t| t.key == "NOTEDATA").skip(1) {
            let description = get(block, "DESCRIPTION");
            if !["Pechersk First Steps", "Pechersk Easy Rhythm"].contains(&description) {
                continue;
            }
            let mut header = vec![Tag {
                key: "NOTEDATA".into(),
                value: String::new(),
            }];
            header.extend_from_slice(block);
            let mut parsed = charts(&header, true);
            if let Some(mut chart) = parsed.pop() {
                chart.difficulty = "Edit".into();
                // Edit radar is recalculated from notes; cached placeholder
                // values would otherwise suppress that calculation.
                let content = render(&chart, true, false, description)
                    .replace("#RADARVALUES:0,0,0,0,0;\n", "");
                let dest = path
                    .parent()
                    .unwrap()
                    .join(format!("{}.edit", description.replace(' ', "-")));
                if dest.exists() {
                    return Err(format!("refusing overwrite: {}", dest.display()).into());
                }
                fs::write(&dest, content)?;
                println!("{}", dest.display());
            }
        }
        return Ok(());
    }
    if args.len() != 3 || !["audit", "generate"].contains(&args[1].as_str()) {
        return Err("usage: easy-charts audit|generate SONGS_DIRECTORY | sidecars GENERATED_SSC (working copies only)".into());
    }
    let root = Path::new(&args[2]);
    let mut files = vec![];
    walk(root, &mut files)?;
    let mut dirs: BTreeMap<PathBuf, Vec<PathBuf>> = BTreeMap::new();
    for p in files {
        if ["sm", "ssc", "dwi"].contains(
            &p.extension()
                .unwrap_or_default()
                .to_string_lossy()
                .to_lowercase()
                .as_str(),
        ) {
            dirs.entry(p.parent().unwrap().into()).or_default().push(p);
        }
    }
    println!("file\ttitle\tcharts\taccessible_beginner\taccessible_easy\taction\tdetails");
    let mut changed = 0;
    let mut added = 0;
    for (dir, mut paths) in dirs {
        if dir.strip_prefix(root)?.components().count() != 2 {
            eprintln!(
                "SKIP nested non-song directory: {}",
                dir.strip_prefix(root)?.display()
            );
            continue;
        }
        paths.sort();
        let chosen = paths
            .iter()
            .find(|p| {
                p.extension()
                    .unwrap_or_default()
                    .to_string_lossy()
                    .eq_ignore_ascii_case("ssc")
            })
            .or_else(|| {
                paths.iter().find(|p| {
                    p.extension()
                        .unwrap_or_default()
                        .to_string_lossy()
                        .eq_ignore_ascii_case("sm")
                })
            })
            .or_else(|| paths.first());
        let Some(path) = chosen else {
            eprintln!("SKIP DWI only: {}", paths[0].display());
            continue;
        };
        let ssc = path
            .extension()
            .unwrap_or_default()
            .to_string_lossy()
            .eq_ignore_ascii_case("ssc");
        let dwi = path
            .extension()
            .unwrap_or_default()
            .to_string_lossy()
            .eq_ignore_ascii_case("dwi");
        let bytes = fs::read(path)?;
        let text = String::from_utf8_lossy(&bytes);
        let t = tags(&text);
        let global: Vec<_> = t
            .iter()
            .take_while(|t| t.key != "NOTEDATA" && t.key != "NOTES")
            .cloned()
            .collect();
        let cs = charts(&t, ssc);
        let mut usable = vec![];
        let mut errors = vec![];
        for c in &cs {
            match Clock::new(&global, c) {
                Ok(clock) => {
                    let st = stats(c, &clock);
                    usable.push((c, clock, st));
                }
                Err(e) => errors.push(e),
            }
        }
        let has_b = usable
            .iter()
            .any(|(c, _, s)| c.single && gentle(s, c.meter, true));
        let has_e = usable
            .iter()
            .any(|(c, _, s)| c.single && gentle(s, c.meter, false));
        let mut additions = String::new();
        let mut details = vec![];
        for (c, _, s) in &usable {
            eprintln!(
                "EXISTING\t{}\t{}\t{}\t{} taps\t{:.2}/s\tgap {:.2}s\t{} jumps\t{} holds\t{} mines",
                path.strip_prefix(root)?.display(),
                c.difficulty,
                c.meter,
                s.events,
                s.rate,
                s.min_gap,
                s.jumps,
                s.holds,
                s.mines
            );
        }
        if text.contains("Pechersk accessible addition v1") {
            details.push("already generated; unchanged".into());
        } else if has_e {
            details.push("existing accessible chart retained".into());
        } else if !has_e
            && let Some((source, clock, _)) = usable
                .iter()
                .filter(|(_, _, s)| s.events >= 12)
                .max_by_key(|(c, _, _)| {
                    rows(&c.notes)
                        .iter()
                        .filter(|(b, r)| {
                            (*b - b.round()).abs() < 0.0001
                                && r.chars().any(|c| matches!(c, '1' | '2' | '4'))
                        })
                        .count()
                })
        {
            // Some legacy SM charts omit their final semicolon; terminate that
            // existing final tag before appending, without altering its bytes.
            if !text.trim_end().ends_with(';') {
                additions.push_str("\n;\n");
            }
            for beginner in [true, false] {
                if (beginner && has_b) || (!beginner && has_e) {
                    continue;
                }
                match generate(source, clock, beginner) {
                    Ok(mut c) => {
                        let st = stats(&c, clock);
                        assert!(
                            st.jumps == 0
                                && st.holds == 0
                                && st.mines == 0
                                && st.min_gap >= if beginner { 0.85 - 1e-6 } else { 0.55 - 1e-6 }
                        );
                        let desc = if beginner {
                            "Pechersk First Steps"
                        } else {
                            "Pechersk Easy Rhythm"
                        };
                        if cs.iter().any(|old| {
                            old.single && old.difficulty.eq_ignore_ascii_case(&c.difficulty)
                        }) {
                            c.difficulty = "Edit".into()
                        }
                        details.push(format!(
                            "{desc}: {} taps, {:.2}/s, min gap {:.2}s",
                            st.events, st.rate, st.min_gap
                        ));
                        additions.push_str(&render(&c, ssc, dwi, desc));
                        added += 1;
                    }
                    Err(e) => details.push(e),
                }
            }
        } else {
            details.extend(errors);
            details.push("no usable source chart".into());
        }
        let action = if additions.is_empty() {
            "keep"
        } else if args[1] == "generate" {
            "added"
        } else {
            "would-add"
        };
        if !additions.is_empty() {
            changed += 1;
            if args[1] == "generate" {
                let mut output = bytes.clone();
                output.extend(additions.as_bytes());
                assert_eq!(&output[..bytes.len()], bytes.as_slice());
                let parsed = charts(&tags(&String::from_utf8_lossy(&output)), ssc);
                assert_eq!(
                    parsed.len(),
                    cs.len()
                        + details
                            .iter()
                            .filter(|s| s.starts_with("Pechersk "))
                            .count()
                );
                fs::write(path, output)?
            }
        }
        println!(
            "{}\t{}\t{}\t{}\t{}\t{}\t{}",
            path.strip_prefix(root)?.display(),
            get(&global, "TITLE").replace(['\n', '\t'], " "),
            cs.len(),
            has_b,
            has_e,
            action,
            details.join("; ")
        );
    }
    eprintln!(
        "{changed} song files, {added} additional charts ({})",
        args[1]
    );
    Ok(())
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn timing_changes_and_stops() {
        let c = Clock {
            bpm: vec![(0., 120.), (8., 60.)],
            pauses: vec![(12., 2.)],
        };
        assert_eq!(c.time(8.), 4.);
        assert_eq!(c.time(16.), 14.);
    }
    #[test]
    fn sm_and_ssc_roundtrip() {
        let source = Chart {
            single: true,
            difficulty: "Hard".into(),
            meter: 10,
            notes: (0..24)
                .map(|_| "1000\n0100\n0010\n0001")
                .collect::<Vec<_>>()
                .join("\n,\n"),
            timing: vec![],
        };
        let clock = Clock {
            bpm: vec![(0., 160.)],
            pauses: vec![],
        };
        for easy in [true, false] {
            let c = generate(&source, &clock, easy).unwrap();
            for ssc in [false, true] {
                let parsed = charts(&tags(&render(&c, ssc, false, "test")), ssc);
                assert_eq!(parsed.len(), 1);
                assert_eq!(rows(&parsed[0].notes), rows(&c.notes));
            }
            let parsed = charts(&tags(&render(&c, false, true, "test")), false);
            assert_eq!(stats(&parsed[0], &clock).events, stats(&c, &clock).events);
            let s = stats(&c, &clock);
            assert_eq!(s.jumps + s.holds + s.mines, 0);
            assert!(s.min_gap >= if easy { 0.85 } else { 0.55 });
        }
    }
    #[test]
    fn split_timing_and_warps_rejected() {
        let t = tags(
            "#BPMS:0=120;#NOTEDATA:;#STEPSTYPE:dance-single;#DIFFICULTY:Hard;#METER:9;#BPMS:0=180;#WARPS:4=8;#NOTES:1000;",
        );
        let cs = charts(&t, true);
        assert!(Clock::new(&t[..1], &cs[0]).is_err());
    }
}
