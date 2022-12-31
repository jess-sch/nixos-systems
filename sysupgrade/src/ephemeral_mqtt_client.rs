pub struct EphemeralMQTTClient {
    topic: String,
    client: paho_mqtt::Client,
    connopts: paho_mqtt::ConnectOptions,
    rx: paho_mqtt::Receiver<Option<paho_mqtt::Message>>,
}

impl EphemeralMQTTClient {
    pub fn new(server_uri: &str, topic: String) -> Self {
        let client = paho_mqtt::Client::new(
            paho_mqtt::CreateOptionsBuilder::new()
                .mqtt_version(5)
                .persistence(None)
                .client_id("")
                .server_uri(server_uri)
                .finalize(),
        )
        .unwrap();
        let connopts = paho_mqtt::ConnectOptionsBuilder::new()
            .keep_alive_interval(std::time::Duration::from_secs(180))
            .clean_start(true)
            .finalize();
        let rx = client.start_consuming();
        Self {
            topic,
            client,
            connopts,
            rx,
        }
    }

    pub fn wait_for_connection(&self, max_retries: Option<u8>) {
        let mut retry = 0;
        while !self.client.is_connected() {
            match self.client.connect(self.connopts.clone()) {
                Ok(x) => {
                    eprintln!("Connected: {}", x.reason_code());
                }
                Err(err) => {
                    retry += 1;
                    eprintln!("Error connecting: {err}");
                    if let Some(max_retries) = max_retries {
                        if max_retries == retry {
                            break;
                        }
                    }
                    std::thread::sleep(std::time::Duration::from_secs(5));
                }
            }
        }
        match self.client.subscribe(&self.topic, 1) {
            Ok(x) => {
                eprintln!("Subscribed: {}", x.reason_code());
            }
            Err(err) => {
                eprintln!("Error subscribing: {err}");
            }
        }
    }

    pub fn recv(&self) -> Option<paho_mqtt::Message> {
        self.rx.recv().unwrap()
    }
    pub fn recv_timeout(&self, timeout: std::time::Duration) -> Option<paho_mqtt::Message> {
        self.rx.recv_timeout(timeout).unwrap()
    }
}
