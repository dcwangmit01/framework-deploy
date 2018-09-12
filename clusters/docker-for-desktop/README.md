# clusters / docker-for-deskop

## Service Discovery

To browse ingress endpoints on your machine, you should add the following host
records to the correct `hosts` file for your operating system.

- MacOS: `/etc/hosts`.
- Windows: `C:\Windows\System32\Drivers\etc\hosts`.

```
127.0.0.1 prometheus.docker-for-desktop.example.org
127.0.0.1 grafana.docker-for-desktop.example.org
127.0.0.1 kibana.docker-for-desktop.example.org
127.0.0.1 alertmanager.docker-for-desktop.example.org
127.0.0.1 pushgateway.docker-for-desktop.example.org
127.0.0.1 prometheus.docker-for-desktop.example.org
```
