# Splunk SIEM Lab

## Overview
A hands-on lab for building and automating **Splunk SIEM clusters** with Docker, Infrastructure as Code (IaC), and CI/CD pipelines.  
This project demonstrates how Splunk components interact in a distributed environment and how DevOps practices can be applied to SIEM engineering.

## Features
- **Phase 1:** Dockerized Splunk cluster with core components (HF, SH, UF, Deployment Server, Indexer).
- **Phase 2:** Infrastructure as Code (IaC) deployment on AWS using Terraform.
- **Phase 3:** CI/CD integration with Jenkins or GitHub Actions for automated builds and deployments.

---

## Architecture

### Phase 1 – Dockerized Splunk Cluster
Components included:
- **Universal Forwarder (UF):** Collects logs from applications and servers.
- **Heavy Forwarder (HF):** Parses and routes data to indexers.
- **Indexer(s):** Stores and processes incoming data.
- **Search Head (SH):** Provides search and visualization capabilities.
- **Deployment Server:** Manages configurations across Splunk instances.

Data Flow: [UF] → [HF] → [Indexer] → [Search Head]

---

### Phase 2 – AWS Infrastructure as Code
- Provision Splunk cluster components on AWS EC2 using **Terraform**.
- Integrate with **S3** for log storage and archival.
- Use **modular Terraform scripts** for scalability and reusability.
- Document AWS architecture with diagrams and usage instructions.

---

### Phase 3 – CI/CD Integration
- Implement **Jenkins pipelines** or **GitHub Actions** for:
  - Building Docker images.
  - Running automated tests on Splunk configs.
  - Deploying updated clusters to AWS.
- Enable **continuous delivery** of dashboards, correlation searches, and alerts.

---

## Quick Start (Phase 1)
Clone the repository and spin up the Dockerized Splunk cluster:

```bash
git clone https://github.com/nphlong/splunk-siem-lab.git
cd splunk-siem-lab
docker compose up -d
```