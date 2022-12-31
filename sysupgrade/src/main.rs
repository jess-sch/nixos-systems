mod ephemeral_mqtt_client;
use std::str::FromStr;

pub use ephemeral_mqtt_client::EphemeralMQTTClient;

const BIN_NIX_ENV: &str = env!("BIN_NIX_ENV");
const BIN_SYSTEMCTL: &str = env!("BIN_SYSTEMCTL");
const SYSTEM_PROFILE: &str = "/nix/var/nix/profiles/system";

#[derive(Debug, clap::Parser)]
struct Opts {
    #[clap(long)]
    mode: OpMode,
    #[clap(long)]
    broker: String,
    #[clap(long)]
    topic: String,
    #[clap(long)]
    action: Option<String>,
}

#[derive(Clone, Debug, clap::ValueEnum)]
enum OpMode {
    Stream,
    Once,
}

fn update(nix_path: &str, action: Option<&str>) {
    let ok = std::process::Command::new(BIN_NIX_ENV)
        .args([
            "--profile",
            SYSTEM_PROFILE,
            "--set",
            nix_path,
        ])
        .spawn()
        .unwrap()
        .wait()
        .unwrap()
        .success();
    if !ok {
        return;
    }
    if let Some(action) = action {
        std::process::Command::new(BIN_SYSTEMCTL)
            .args(["start", "--no-block", action])
            .spawn()
            .unwrap()
            .wait()
            .unwrap();
    }
}

fn main() {
    let opts: Opts = clap::Parser::parse();
    let client = EphemeralMQTTClient::new(&opts.broker, opts.topic);

    let action = opts.action.as_ref().map(String::as_str);

    let mut current_path = std::fs::canonicalize(SYSTEM_PROFILE).unwrap_or_default();

    match opts.mode {
        OpMode::Once => {
            if !client.wait_for_connection(Some(1)) {
                std::process::exit(1);
            }
            let msg = client
                .recv_timeout(std::time::Duration::from_secs(5))
                .unwrap();
            let nix_path = msg.payload_str();
            update(&nix_path, action);
        }
        OpMode::Stream => {
            client.wait_for_connection(None);
            loop {
                match client.recv() {
                    Some(msg) => {
                        let nix_path = msg.payload_str();
                        let new_path = std::path::PathBuf::from_str(&nix_path).unwrap();
                        if current_path == new_path {
                            eprintln!("Already up to date, not doing anything");
                        }else {
                            current_path = new_path;
                            update(&nix_path, action);
                        }
                    }
                    None => {
                        eprintln!("Disconnected");
                        client.wait_for_connection(None);
                    }
                }
            }
        }
    }
}
