# Docker Samples :: Avatars 🤪
Avatars is a small sample project for Docker demonstration purposes.

It consists of a Python web API backend to generate avatars and a Javascript SPA (single page app) frontend.
If you are not a Python or Javascript guru, don't panic!

## Usage
To get started, clone this repository locally:
```shell
git clone https://github.com/dockersamples/avatars.git
```
All subsequent commands assume they are run from the root repository directory
(i.e. `avatars/` folder).

Run `make help` to see a list of available targets.

### Tilt
You'll need to first install Tilt and prerequisites (Docker + development Kubernetes cluster).

Run `tilt up` or `make tilt`.
All resources will be deployed to the namespace and cluster as determined by the active Kubernetes config context.

* Tilt web interface: http://localhost:10350/
* Avatars frontend: http://localhost:5735/
* Avatars API: `curl http://localhost:5734/api/avatar/spec`

### Docker Compose with file watch
Run `make compose`.

* Avatars frontend: http://localhost:5735/

Compose launches the services and attaches in file watch mode.
Run `docker compose -p avatars logs -f` from a separate terminal to stream logs. 

### Kubernetes (Docker Desktop)
> ℹ️ If you haven't already, open the Docker Desktop dashboard and enable
> Kubernetes from `Settings > Kubernetes > ☑️ Enable Kubernetes` and apply.

Run `make kubernetes`.
All resources will be deployed to the `avatars` namespace in the `docker-desktop` Kubernetes cluster.

* Avatars frontend: http://localhost:5735/

Buildx builds images and Kubernetes creates `Deployment`s and `Service`s.
The images are not pushed to a registry, as Docker Desktop's Kubernetes
integration runs the images directly from the Docker Engine image store using
[cri-dockerd][] (formerly known as `dockershim`).

Run `kubectl --context=docker-desktop --namespace=avatars logs -l='app.kubernetes.io/part-of=dockersamples_avatars' from a separate terminal to stream logs.

[cri-dockerd]: https://github.com/Mirantis/cri-dockerd


## Simple Compose Watch Test


```
git clone https://github.com/dockersamples/avatars
cd avatars
docker compose up -d
```

## Initiate the Watch

```
docker compose watch
```

## Generate a graphviz graph from your compose file

```
docker compose alpha viz
```
## DevOps Mini Project

This project builds on the Docker Samples Avatar Generator.

Our goal is to implement automated testing, Docker image builds, and image publishing using GitHub Actions, followed by repeatable local deployment with Docker Compose.

Current progress:
- Started the frontend and API locally using Docker Compose.
- Verified that avatar customization works.
- Confirmed that the API returns avatar configuration data.

Original project: https://github.com/dockersamples/avatars

### Implemented DevOps workflow

Pull request -> container builds -> two API tests -> frontend compilation.
After a merge to main passes those checks, GitHub Actions builds and publishes
API and web images to GitHub Container Registry. Images have both a full Git
commit tag and a moving `latest` tag. Deployment to the laptop is manually
triggered; this project does not claim automatic continuous deployment.

### Deploy published images on Windows

Start Docker Desktop in Linux container mode. From this repository in PowerShell:

```powershell
# Use the full commit ID of a successful publishing run on GitHub Actions.
# Immediately after pulling a successfully published main, this is its commit:
$env:AVATAR_IMAGE_TAG = git rev-parse HEAD
docker compose -f compose.deploy.yaml pull
docker compose -f compose.deploy.yaml up -d --no-build --wait --wait-timeout 120
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify.ps1
docker compose -f compose.deploy.yaml ps
```

Stop if a command fails. Both images must have been published for the chosen
commit. New documentation commits cannot be used as image tags until their
publishing workflow succeeds. If a package requires authentication, sign in to
GHCR locally; never put access tokens in source code, screenshots, or the report.

This deployment file uses the same Compose project and service names as the
development configuration, so it replaces those two containers. It downloads
published images without rebuilding locally. Frontend: http://localhost:5735/.
API: http://localhost:5734/api/avatar/spec. Wait for both services to be healthy.

### Demonstration and evidence

1. Show the original repository attribution and your own Git branches and PRs.
2. Show a successful PR check and the main-branch publishing jobs in Actions.
3. Show both GHCR packages and their commit-specific image tags.
4. Run the deployment commands above; capture both healthy containers and all
   five verification checks passing. Show avatar customization in the browser.
5. Inspect resource usage with `docker stats --no-stream` and service output with
   `docker compose -f compose.deploy.yaml logs --tail 30`.
6. Demonstrate a controlled API outage and recovery:

```powershell
docker compose -f compose.deploy.yaml stop api
curl.exe --noproxy '*' --max-time 5 http://127.0.0.1:5734/ready
# Connection failure is expected while the API is deliberately stopped.
docker compose -f compose.deploy.yaml up -d --no-build --wait --wait-timeout 120
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify.ps1
```

The recovery in this demonstration is manual. A health check reports an unhealthy
service; it does not itself restart a running unhealthy process. The restart
policy handles unexpected container exits, not deliberate `docker compose stop`.

For a negative CI demonstration, create a temporary branch, deliberately change
one test expectation, and open a PR. Capture the failed check; then restore the
test and push again to show recovery. Do not merge a failing change. Publishing
on main depends on successful checks; blocking PR merges additionally requires
GitHub branch protection/rulesets, which are not configured by this workflow.

### Scope, limitations, and report

This is a local teaching deployment. The upstream Flask and Vite development
servers remain in the images; production server hardening, Nginx, automatic
deployment, Kubernetes, and advanced monitoring are future scope. There is no
database or persistent user account storage in this application.

Suggested report title: **Continuous Integration and Containerized Deployment
of an Avatar Generator using GitHub Actions and Docker**.

- Introduction: manual builds and deployments can be inconsistent; define a
  repeatable test, package, publish, and deployment workflow.
- Background: Git/PRs, CI, images versus containers, registries, and Compose.
- Requirements: Windows, Docker Desktop, Git, GitHub, browser, and internet.
- Design: browser -> web container; browser/API calls -> Flask container.
  Delivery: GitHub -> Actions -> GHCR -> local Docker Compose.
- Implementation: explain tests, workflow triggers, job dependencies, commit
  tags, health checks, and the deployment verification script.
- Results: include your actual screenshots, workflow timings, and test output;
  distinguish unit checks, frontend compilation, and deployment smoke checks.
- Challenges: record branch tracking, merging versus pulling, and troubleshooting.
- Conclusion: automated CI and publishing with manually triggered local deployment.
- References: credit Docker Samples and cite GitHub Actions and Docker docs.

Our additions are the API tests, Actions workflow, GHCR publishing, deployment
configuration, verification script, and documented experiments. The original
avatar application remains credited to its upstream authors.
