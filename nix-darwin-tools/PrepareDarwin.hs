#! /usr/bin/env nix-shell
#! nix-shell -i runhaskell
{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}

module PrepareDarwin where

import           Control.Monad             (forM_)
import           Data.Text                 (Text)
import qualified Data.Text                 as T
import qualified Data.Text.IO              as T
import           Filesystem.Path.CurrentOS (decodeString)
import           Prelude                   hiding (FilePath)
import           System.Environment        (getEnv, getExecutablePath)
import           System.IO                 (hFlush)
import           Turtle

prepare :: IO ()
prepare = sh installNixDarwin

-- | Install nix-darwin
installNixDarwin :: Shell ()
installNixDarwin = do
  checkNix
  setupSSLCert
  prepareConfigs
  liftIO setupUserBashrc
  createRunDir
  restartDaemon
  sleep 2.0
  --cleanupEtc

checkNix :: Shell ()
checkNix = sh $ which "nix-build" >>= \case
  Just nb -> procs (tt nb) ["--version"] empty
  Nothing -> do
    echo "nix-build was not found. Installing nix"
    -- Nix fails to install if these backup files exist
    mapM_ restoreFile ["/etc/bashrc", "/etc/zshrc"]
    empty & inproc "curl" ["https://nixos.org/nix/install"] & inproc "sh" [] & stdout

-- | This is a workaround for nix curl on Darwin.
setupSSLCert :: Shell ()
setupSSLCert = unlessM (testfile cert) $ mapM_ sudo setup
  where
    cert = "/etc/ssl/cert.pem"
    bundle = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt"
    setup = [ [ "mkdir", "-p", tt $ directory cert ]
            , [ "ln", "-sf", tt bundle, tt cert ] ]

-- | Prepare /etc for use with nix-darwin instead of nix.
prepareConfigs :: Shell ()
prepareConfigs = do
  -- prepare configs for nix darwin
  user <- liftIO $ getEnv "USER"
  mapM_ moveAway ["/etc/nix/nix.conf"]
  let contents = fromString $ "trusted-users = " <> user
  liftIO $ writeTextFile "./nix.conf" contents
  sudo [ "cp", "./nix.conf", "/etc/nix/nix.conf" ]
  chopProfile "/etc/profile"

moveAway :: FilePath -> Shell ()
moveAway cfg = do
  let backup = cfg <.> "backup-before-nix-darwin"
  exists <- testpath cfg
  backupExists <- testpath backup
  when (exists && not backupExists) $ do
    st <- stat cfg
    when (isRegularFile st || isDirectory st) $
      sudo ["mv", tt cfg, tt backup]

restoreFile :: FilePath -> Shell ()
restoreFile cfg = do
  let backup = cfg <.> "backup-before-nix"
  exists <- testpath cfg
  backupExists <- testpath backup
  when backupExists $ do
    when exists $
      sudo ["rm", tt cfg]
    sudo ["mv", tt backup, tt cfg]

-- | Delete everything after the # Nix line
chopProfile :: FilePath -> Shell ()
chopProfile p = do
  contents <- input p & limitWhile (/= "# Nix") & strict
  (temp, h) <- using (mktemp "/tmp" "profile")
  liftIO $ T.hPutStr h contents
  liftIO $ hFlush h
  sudo ["cp", tt temp, tt p]

-- | This is needed so that nix-copy-closure to this host will work
setupUserBashrc :: IO ()
setupUserBashrc = do
  homeDir <- getEnv "HOME"
  writeTextFile (fromString homeDir </> ".bashrc") "source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"

-- | nixpkgs things need /run and normally the nix-darwin installer creates it
createRunDir :: Shell ()
createRunDir = unlessM (testpath "/run") $
  sudo ["ln", "-s", "private/var/run", "/run"]

setupDotNixpkgs :: Shell FilePath
setupDotNixpkgs = do
  dotNixpkgs <- (</> ".nixpkgs") <$> home
  unlessM (testdir dotNixpkgs) $ mkdir dotNixpkgs
  pure dotNixpkgs

restartDaemon :: Shell ()
restartDaemon = do
  sudo [ "launchctl", "stop", "org.nixos.nix-daemon" ]
  sudo [ "launchctl", "start", "org.nixos.nix-daemon" ]

cleanupEtc :: Shell ()
cleanupEtc = do
  sudo [ "rm", "-f", "/etc/nix/nix.conf" ]
  sudo [ "rm", "-f", "/etc/bashrc" ]
  sudo [ "rm", "-f", "/etc/zshrc" ]

-- | Create a directory for secret files which shouldn't go in nix store.
sudo :: [Text] -> Shell ()
sudo cmd = do
  liftIO . T.putStrLn . T.unwords $ ("sudo":cmd)
  procs "sudo" cmd empty

tt :: FilePath -> Text
tt = format fp

unlessM :: Monad f => f Bool -> f () -> f ()
unlessM f a = f >>= \t -> if t then pure () else a

whenM :: Monad f => f Bool -> f () -> f ()
whenM f a = f >>= \t -> if t then a else pure ()
