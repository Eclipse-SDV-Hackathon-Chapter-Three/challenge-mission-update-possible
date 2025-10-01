# OTA Updates for ECUs (HPC Variant)

In this variant, you will develop an end-to-end Over-The-Air (OTA) update workflow using [Eclipse Symphony](https://projects.eclipse.org/projects/iot.symphony) as a cloud-based meta orchestrator and [Eclipse Ankaios](https://github.com/eclipse-ankaios/ankaios/tree/v0.6.0) as the in-vehicle embedded software orchestrator for managing SDV workloads.

At the end, Eclipse Symphony should push updates from the cloud to the Symphony Target Rust Provider workload, managed by Eclipse Ankaios inside the vehicle. To achieve this, you must implement a Rust provider and extend the existing Symphony Target Provider workload.

For quick onboarding, both the cloud (simulated locally on your machine) and the in-vehicle parts are preconfigured.

The cloud component is launched through a Docker Compose file that includes the Eclipse Symphony management plane, an MQTT broker (based on [Eclipse Mosquitto](https://mosquitto.org/)) for delivering updates to the vehicle, and a read-only Symphony portal.  

The in-vehicle component is managed via Eclipse Ankaios and comes with a predefined [Ankaios manifest](https://eclipse-ankaios.github.io/ankaios/0.6/reference/startup-configuration/) called [state.yaml](./ankaios/state.yaml), which launches the following workloads:

- `update_trigger`: a web-based workload accessible at `http://localhost:5500` with a button to instruct Eclipse Ankaios to start the `symphony` in-vehicle workload.
- `symphony`: the Symphony Target Provider workload that receives updates over MQTT from the Symphony management plane in the cloud.
- `Ankaios_Dashboard`: The [Ankaios Dashboard](https://github.com/eclipse-ankaios-dashboard/ankaios-dashboard/tree/v0.6.0) visualizing an Ankaios cluster in a WebUI.

The `update_trigger` workload uses the Ankaios SDK [ank-sdk-python](https://github.com/eclipse-ankaios/ank-sdk-python/tree/v0.6.0) to dynamically start the `symphony` in-vehicle workload. In real-world scenarios, ECU updates are typically triggered only under certain conditions (e.g., when the vehicle is parked at home). You can use Eclipse Ankaios’ dynamic features to start workloads programmatically. The workload runs a FastAPI backend that provides a simple `Update` button to trigger the update. Normally, a user must confirm an update, which serves as a foundation for an enhanced workflow. Once triggered, the Ankaios SDK instructs Ankaios to start the `symphony` provider workload, which fetches updates from the Symphony cloud control plane over MQTT. implementing the update logic is your task by creating a `Symphony Target Rust Provider`. Feel free to enhance this basic scenario.

**Updating SDV workloads:**

Write a custom workload and start it with Ankaios by adding the workload configuration to the existing Ankaios manifest [state.yaml](./ankaios/state.yaml). Use Symphony and the Symphony Agent Provider workload to update your custom workload to a newer version.

**Updating an ECU:**

Try to connect a Eclipse ThreadX board and try to update this from an updater workload implemented by you. To flash the ThreadX board with a new software, you may use the following [flash script](https://github.com/odlot/challenge-threadx-and-beyond/blob/36819d3aaff639e80dc441412acf88f6b3a705ce/MXChip/AZ3166/scripts/flash.sh). Think about how to integrate the update procedure to flash ThreadX into an containerized workload managed by Ankaios. As hint: You can put a container into `privileged` mode and also mount the USB device into the container.

## Architectural Overview

```
Eclipse Symphony (Cloud Meta Orchestrator)
        ↓ MQTT/API
Eclipse Symphony Provider Agent managed by Eclipse Ankaios (in-vehicle orchestrator)
        ↓ Ankaios Control Interface
Eclipse Ankaios
        ↓ Starts/Updates
In-vehicle Workloads/ECUs
```
- [Ankaios Control Interface](https://eclipse-ankaios.github.io/ankaios/0.6/reference/control-interface/)

## Prerequisites

- Any Linux or WSL2 on Windows
- [Eclipse Symphony 0.48-proxy.41](https://github.com/eclipse-symphony/symphony/releases/tag/0.48-proxy.41)
- [Eclipse Ankaios v0.6.0](https://github.com/eclipse-ankaios/ankaios/releases/tag/v0.6.0)
- [Podman](https://podman.io/docs/installation#installing-on-linux)
- [Docker](https://www.docker.com/) with Compose support

## Installation

### Install Podman

On Ubuntu:

```
sudo apt-get update
sudo apt-get -y install podman
```

Otherwise follow the official [Podman installation instructions](https://podman.io/docs/installation#installing-on-linux).

### Install Docker

Follow the instructions in the official [Install Docker Engine Guideline](https://docs.docker.com/engine/install/). Next, [intall docker compose](https://docs.docker.com/compose/install/).

### Install Ankaios

Install Eclipse Ankaios with a single curl command as described in the [Ankaios installation guide](https://eclipse-ankaios.github.io/ankaios/latest/usage/installation).

Follow the `Setup with script` section and install version v0.6.0.

**Note:** On Ubuntu 24.04, disable AppArmor as described in the guide.

The installation script automatically creates systemd service files for the Ankaios server and agent.

To enable `ank-cli` shell completion (for auto-completing workload names and field masks), follow the [Ankaios shell completion setup](https://eclipse-ankaios.github.io/ankaios/0.6/usage/shell-completion).

### Install Symphony

No installation is required; the cloud component is launched via Docker Compose.

### Docker Desktop for MacOS and Windows users

First you need to upgrade to newer Docker Desktop versions so that "host networks" are supported.

Enable the option `Settings->Resources->Networking->Enable Host Networking`.

You can run the challenge without a Linux VM by just using the prebuilt Ankaios app devcontainer that includes Ankaios installation and Podman inside a container.

Lunch everything with Docker Desktop.

Start the cloud part like described below in [Start the cloud part](#start-the-cloud-part).

Start the Ankaios app devcontainer v0.6.0 with the following command and mount the whole challenge repository into the container:

```shell
docker run --privileged --network host -it -v ./:/workspace --workdir /workspace  ghcr.io/eclipse-ankaios/app-ankaios-dev:0.6.0
```

Now, you work with Ankaios in the container (container in container) but still can modify the files using your preferered local editor.

Move on with [Start the in-vehicle part](#start-the-in-vehicle-part), but do not try to start Ankaios with systemd since it is not part of the Ankaios app container. Instead, start manually ank `ank-server` and an `ank-agent` with name `agent_A` and apply the [state.yaml](./ankaios/state.yaml):

```shell
ank-server > /dev/null 2>&1 &
ank-agent --name agent_A > /dev/null 2>&1 &
```

You are using Ankaios and podman rootless now, so if you build a container image inside the Ankaios app container, then you have to use `podman build` instead of `sudo podman build`.

After applying the `state.yaml` all services are visible on the localhost, which you can optionally check with:

```shell
sudo lsof -iTCP -sTCP:LISTEN -P -n
```

Feel free to make Visual Studio Devcontainer out of it if you want better development experience.

## Run the demo

### Start the cloud part

Launch Symphony, an MQTT broker, and a read-only Symphony portal using the provided Docker Compose file like described in [../symphony/README.md](../symphony/README.md).

### Start the in-vehicle part

Start the Ankaios server and Ankaios agent with systemd:

```shell
sudo systemctl start ank-server ank-agent
```

The example uses an `update_trigger` workload which is added as prebuilt container image (`ghcr.io/eclipse-sdv-hackathon-chapter-three/mission-update/update_trigger:latest`) to the Ankaios manifest [state.yaml](./ankaios/state.yaml) already. However, if the network quality is too poor to download the prebuilt image, please build the container image locally like discribed in [ankaios/custom_workloads/update_trigger/README.md](./ankaios/custom_workloads/update_trigger/README.md) and exchange the container image in the Ankaios manifest to point to the local one.

To run the over-the-air (OTA) scenario, just apply the [state.yaml](./ankaios/state.yaml) containing the workloads of the demo screnario:

```shell
ank apply ankaios/state.yaml
```

For applying incremental changes during the development you might update the [state.yaml](./ankaios/state.yaml) multiple times. The `ank apply` command figures out changes to the manifest by itself and applies only the changes, which means you can apply the new manifest and the workloads will get updated. You can also remove all the applied workloads by simply running `ank apply -d ankaios/state.yaml`. Just stopping the Ankaios cluster using systemd keeps the workloads and containers on `Podman`.

### Do the demo

1. Open the Ankaios Dashboard at `http://localhost:5001` and go to the Workloads tab.
2. Open the `update_trigger` WebUI at `http://localhost:5500` and click the Trigger Update button. You should see a successfull toast message at the bottom after a while (the first start is slow because the `symphony` container image must be downloaded first times, open a new terminal and check the state of the new workloads with `ank get workloads --watch`).
3. The `update_trigger` workload sets the empty agent name of the `symphony` workload (Symphony Target Provider) to the running Ankaios Agent named `agent_A` via the Ankaios Python SDK. This instructs Ankaios to schedule and start the `symphony` workload.
4. The `symphony` workload connects to the Symphony cloud management plane via MQTT and is ready to receive updates.
5. You can see in the Ankaios Dashboard, that the `symphony` workload is running.
6. With executing `ank get workloads` in the terminal, you should see now all workloads running:

```text
WORKLOAD NAME       AGENT     RUNTIME   EXECUTION STATE   ADDITIONAL INFO
Ankaios_Dashboard   agent_A   podman    Running(Ok)
symphony            agent_A   podman    Running(Ok)
update_trigger      agent_A   podman    Running(Ok)
```
7. Open a terminal window and navigate to `samples/ankaios_provider` and execute the script `test_ankaios_provider.sh`. You can use the script to create and then destroy a Target (named `ankaios-target`). It sends the provided sample target definition `target.json` containing a new workload `ankaios-app` with a Nginx container to the Symphony management plane and the Symphony Agent Provider workload receives this payload and instructs Ankaios to create this new workload. Target definition snippet:
```json
{
    "name": "ankaios-app",   
    "type": "ankaios-workload",             
    "properties": {
        "ankaios.runtime": "podman",
        "ankaios.agent": "agent_A",
        "ankaios.restartPolicy": "NEVER",
        "ankaios.runtimeConfig": "image: docker.io/library/nginx\ncommandOptions: [\"-p\", \"8080:80\"]"                   
    }
}
```

8. Execute `ank get workloads` again and now you should see an additional workload `ankaios-app` in the state `Running(Ok)`. You can also access the nginx start page with `curl http://localhost:8080`.
9. Go back to `test_ankaios_provider.sh` terminal window and press enter. The `ankaios-app` workload is removed again.

Using Symphony and Ankaios, you can deploy new workloads (add workloads to `target.json`) to the vehicle or update existing workloads (set a newer container image in `target.json`).

For debugging, view logs of any workload:

```shell
ank logs --follow <workload_name>
```

Replace `<workload_name>` with the workload name for which you want to see the logs.

Proceed to the next steps to enhance this basic scenario with your custom update workflow.

## Additional Ankaios commands

```
ank get state // Retrieve information about the current Ankaios system
ank get workload // Information about the worloads running in the Ankaios system
ank get agent // Information about the Ankaios agents connected to the Ankaios server
ank logs <workload_name> // Retrieve the logs from a workload
ank help // Get the help
```

## Next Steps

* [Write a custom Symphony Target provider using Rust](./rust_provider.md)
* [Set up a standalone Symphony Agent](./symphony_standalone.md)
* Write more custom workloads like [custom_workloads/update_trigger](./ankaios/custom_workloads/update_trigger/) to enhance the update challenge