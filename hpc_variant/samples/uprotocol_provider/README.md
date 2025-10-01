## Prerequisites

* [Rust toolchain installed](https://rustup.rs/) on your local machine
* Podman installed as described in the [Ankaios README](../../README.md)
* [ECU Updater example application](https://github.com/eclipse-uprotocol/symphony-target-example-rust) running on your machine

## Steps

1. Make sure that the Symphony agent Ankaios workload is not running
   ```bash
   ank get workloads
   ```
   If necessary, stop the _symphony_ workload
   ```bash
   ank delete workload symphony
   ```
2. Clone the Symphony repository
   ```bash
   git clone https://github.com/boschglobal/symphony.git
   ```
   and switch to the `add_uprotocol_target_provider` branch
   ```bash
   cd symphony
   git checkout add_uprotocol_target_provider
   ```
3. Build the Rust based target providers
   ```bash
   cd api/pkg/apis/v1alpha1/providers/target/rust
   cargo build --release
   ```
4. Create a Podman volume for holding the uProtocol Target Provider library:
   ```bash
   sudo podman volume create hackathon-extensions
   HACKATHON_EXTENSIONS_VOLUME_PATH=$(sudo podman volume inspect --format "{{ .Mountpoint }}" hackathon-extensions)
   sudo cp target/release/libuprotocol.so "$HACKATHON_EXTENSIONS_VOLUME_PATH"
   ```
   The Symphony agent is configured to look inside of this volume for additional target providers. So when you create a Target that refers to the uProtocol Target Provider using the Symphony API, then the Symphony agent will load the library from this volume and let it handle the request to create the target.
5. Apply the Ankaios state to start the Ankaios Dashboard and the update trigger application.
   ```bash
   cd $REPO_ROOT/hpc_variant/ankaios/samples/uprotocol_provider
   ank apply ./state.yaml
   ```
6. Open the [Update Trigger Application](http://localhost:5500) and click the button
7. Verify that the Symphony agent workload has started successfully
   ```bash
   ank get workloads
   WORKLOAD NAME       AGENT     RUNTIME   EXECUTION STATE   ADDITIONAL INFO
   Ankaios_Dashboard   agent_A   podman    Running(Ok)                      
   symphony            agent_A   podman    Running(Ok)                      
   update_trigger      agent_A   podman    Running(Ok)  
   ```
8. Deploy some ECU firmware by means of the ECU Updater application
   ```bash
   ./test_uprotocol_provider.sh
   ```
   This should result in the ECU Updater application printing some info to the console that looks like
   ```bash
   [2025-10-01T08:08:14Z INFO  ecu_updater] processing GET request [from: up://symphony/DA00/1/0]
   [2025-10-01T08:08:14Z INFO  ecu_updater] processing GET request [from: up://symphony/DA00/1/0]
   [2025-10-01T08:08:14Z INFO  ecu_updater] processing request [method: up://ecu-updater.app/A100/1/2, from: up://symphony/DA00/1/0]
   [2025-10-01T08:08:14Z INFO  ecu_updater::deployment_state] installing firmware [name: Engine Controller, FW Image: "https://acme.io/fw/engine-control-1.45.img"]
   [2025-10-01T08:08:14Z INFO  ecu_updater::deployment_state] installing firmware [name: Telematics Unit, FW Image: "https://non-existent.io/fw/telematics-unit-2.0.img"]
   ```
