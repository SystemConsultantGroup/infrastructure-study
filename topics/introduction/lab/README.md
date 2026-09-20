# SCG Week 1 Lab

This directory contains the complete minimal HTTP service used for the Introduction + Docker study.

## Files

- `StudyApi.java`: minimal Java HTTP service
- `flake.nix`: Nix development shell and Linux image definition
- `flake.lock`: pinned Nix input revision
- `smoke.sh`: six-check smoke test

## Run in a local IDE

Open this directory in VS Code or IntelliJ IDEA.

### With Nix

From this directory:

```bash
nix develop
mkdir -p build
javac --release 21 -d build StudyApi.java
java -cp build StudyApi
```

In another terminal:

```bash
curl http://127.0.0.1:8080/health
curl http://127.0.0.1:8080/info
```

Stop the server with `Ctrl+C`, then leave the development shell with `exit`.

### Without Nix

Install Java 21 and `curl` locally, then run the same compile and run commands. This path uses the host environment and is therefore less reproducible.

`nix develop` prepares development tools. It is not a container or a virtual machine.
