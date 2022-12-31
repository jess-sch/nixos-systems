mod ephemeral_mqtt_client;
pub use ephemeral_mqtt_client::EphemeralMQTTClient;

#[derive(Debug, clap::Parser)]
struct Opts {
    action: String,
    #[clap(long)]
    rollback: bool,
    #[clap(long)]
    broker: Option<String>,
    #[clap(long)]
    topic: Option<String>,
}

#[derive(Debug, serde::Deserialize)]
struct Config {
    broker: String,
    topic: String,
}

fn main() {
    let mut opts: Opts = clap::Parser::parse();

    if opts.broker.is_none() || opts.topic.is_none() {
        let b = std::fs::read("/etc/sysupgrade.json").expect("Missing /etc/sysupgrade.json");
        let c: Config = serde_json::from_slice(&b).expect("Error parsing /etc/sysupgrade.json");
        opts.broker.get_or_insert(c.broker);
        opts.topic.get_or_insert(c.topic);
    }

    let broker = opts.broker.expect("No broker set");
    let topic = opts.topic.expect("No topic set");
    let client = EphemeralMQTTClient::new(&broker, topic);

    client.wait_for_connection(None);
    loop {
        match client.recv() {
            Some(msg) => {
                let topic = msg.topic();
                let nix_path = msg.payload_str();
                println!("{topic}: {nix_path}");
                if let Ok(path) = std::fs::canonicalize("/nix/var/nix/profiles/system") {
                    if nix_path == path.display().to_string() {
                        eprintln!("{nix_path} is already the current version!");
                        continue;
                    }
                }
                println!("$ nix-env --profile /nix/var/nix/profiles/system --set {nix_path}");
                println!(
                    "$ /nix/var/nix/profiles/system/bin/switch-to-configuration {}",
                    opts.action
                );
            }
            None => {
                eprintln!("Disconnected");
                client.wait_for_connection(None);
            }
        }
    }
}
