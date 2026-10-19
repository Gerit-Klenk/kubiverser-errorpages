# 🌌 Kubiverse Error Pages für Traefik in Kubernetes

Maßgeschneiderte, moderne HTTP-Fehlerseiten (400, 401, 403, 404, 500, 502, 503, 504) für den **Traefik Ingress Controller** in Kubernetes – optisch und stilistisch nahtlos abgestimmt auf das **FMS-Kubiverse DevOps Portal**.

---

## 📋 Inhaltsverzeichnis

1. [Funktionsweise & Architektur](#-funktionsweise--architektur)
2. [Unterstützte Fehlercodes](#-unterst%C3%BCtzte-fehlercodes)
3. [Projektstruktur](#-projektstruktur)
4. [Lokale Vorschau & Testen](#-lokale-vorschau--testen)
5. [Bereitstellung im Kubernetes-Cluster](#-bereitstellung-im-kubernetes-cluster)
   - [Option A: Zero-Build via ConfigMap (Empfohlen für schnellen Start)](#option-a-zero-build-via-configmap-schnellste-methode)
   - [Option B: Eigenes Docker-Image](#option-b-eigenes-docker-image-klassische-methode)
6. [Traefik `values.yaml` Konfiguration](#-traefik-valuesyaml-konfiguration)
   - [Globale Einbindung auf allen EntryPoints](#1-globale-einbindung-in-valuesyaml-f%C3%BCr-alle-routen)
   - [Einbindung pro Ingress oder IngressRoute](#2-einbindung-pro-ingress--ingressroute)
7. [Fehlerseiten testen & verifizieren](#-fehlerseiten-testen--verifizieren)
8. [Anpassung von Texten & Branding](#-anpassung-von-texten--branding)

---

## 🔍 Funktionsweise & Architektur

Traefik nutzt für individuelle Fehlerseiten die **Errors Middleware** (`Middleware` CRD).

```
                      +---------------------------------------+
                      |       Eingehende Client-Anfrage       |
                      +---------------------------------------+
                                          |
                                          v
                      +---------------------------------------+
                      |        Traefik Ingress Router         |
                      |    (Prüft Route, SSL & Host-Regeln)   |
                      +---------------------------------------+
                                     /         \
                 Status 200-399     /           \  Status 400-599
                                   /             \ (z. B. 404, 502, 503)
                                  v               v
                +--------------------+   +------------------------------------+
                |  Anwendungs-Pod    |   |  Traefik Errors Middleware         |
                |  (Dein Service)    |   |  -> Ruft intern Error-Service auf: |
                +--------------------+   |     http://kubiverse-error-pages   |
                                         |     query: /{status}.html          |
                                         +------------------------------------+
                                                          |
                                                          v
                                         +------------------------------------+
                                         |  Kubiverse Error Pages (Nginx)     |
                                         |  (Liefert gestylte HTML-Seite mit  |
                                         |   ursprünglichem HTTP-Statuscode)  |
                                         +------------------------------------+
```

1. Antwortet ein Upstream-Pod mit einem Fehlercode (z. B. `502 Bad Gateway`, `503 Service Unavailable`) oder findet Traefik keinen passenden Router (`404 Not Found`), fängt die Middleware die Antwort ab.
2. Traefik holt die entsprechende Seite `/{status}.html` vom `kubiverse-error-pages` Service.
3. Der Browser erhält die ansprechende Kubiverse-Fehlerseite, während der HTTP-Statuscode (`404`, `502`, etc.) für APIs und Monitoring korrekt erhalten bleibt.

---

## 🎨 Unterstützte Fehlercodes

| Statuscode | Name | Beschreibung im Kubiverse-Design |
| :--- | :--- | :--- |
| **400** | Bad Request | Ungültige oder fehlerhafte HTTP-Anfrage an das Gateway |
| **401** | Unauthorized | Fehlende oder abgelaufene Authentifizierung |
| **403** | Forbidden | Zugriff auf Cluster-Ressource verweigert (RBAC) |
| **404** | Not Found | Route, Ingress oder Ziel-Deployment existiert nicht |
| **500** | Internal Server Error | Unerwarteter Anwendungsfehler im Ziel-Pod |
| **502** | Bad Gateway | Ziel-Pod nicht erreichbar (Container startet / Crash) |
| **503** | Service Unavailable | Wartungsarbeiten oder Skalierung im Cluster |
| **504** | Gateway Timeout | Pod hat innerhalb des Traefik-Timeouts nicht geantwortet |
| **index.html** | Hub & Vorschau | Interaktiver Previewer mit Reiter-Navigation und dynamischer Parameterunterstützung (`?code=502`) |

---

## 📁 Projektstruktur

```
kubiverse-error-pages/
├── Dockerfile                      # Schlankes, unprivilegiertes Nginx-Image (Alpine)
├── nginx.conf                      # Gehärtete Nginx-Konfiguration mit /healthz & Security-Headern
├── docker-compose.yml              # Lokales Testen mit einem Befehl
├── README.md                       # Diese Dokumentation
├── src/
│   ├── index.html                  # Interaktive Übersicht & dynamischer Error-Handler
│   ├── 400.html                    # 400 Bad Request
│   ├── 401.html                    # 401 Unauthorized
│   ├── 403.html                    # 403 Forbidden
│   ├── 404.html                    # 404 Not Found
│   ├── 500.html                    # 500 Internal Server Error
│   ├── 502.html                    # 502 Bad Gateway
│   ├── 503.html                    # 503 Service Unavailable
│   ├── 504.html                    # 504 Gateway Timeout
│   ├── css/
│   │   └── style.css               # Kubiverse Design-Tokens, Glasmorphismus & Animationen
│   └── assets/
│       ├── logo.svg                # FMS-Kubiverse Logo
│       └── favicon.svg             # Favicon
└── k8s/
    ├── deployment.yaml             # Kubernetes Deployment
    ├── service.yaml                # ClusterIP Service (Port 80 -> 8080)
    ├── traefik-middleware.yaml     # Traefik Errors Middleware CRD
    ├── configmap-deployment.yaml   # Sofort-Deploy ohne eigene Docker Registry
    ├── traefik-values-snippet.yaml # Vorlage für Traefik values.yaml
    ├── ingress-example.yaml        # Anwendungsbeispiele für Ingress & IngressRoute
    └── kustomization.yaml          # Kustomize Bundle
```

---

## 💻 Lokale Vorschau & Testen

Du kannst die Fehlerseiten sofort lokal ansehen, ohne Kubernetes:

### Mit Docker Compose:
```bash
docker compose up -d
```
Öffne anschließend [http://localhost:8085](http://localhost:8085) im Browser. Dort kannst du mit den Buttons oben bequem zwischen allen Fehlercodes hin- und herwechseln!

### Mit Python:
```bash
python3 -m http.server 8085 --directory src
```

---

## 🚀 Bereitstellung im Kubernetes-Cluster

Stelle sicher, dass dein `kubectl` Kontext auf den Zielcluster zeigt und der Namespace existiert (in diesem Beispiel `traefik`):

```bash
kubectl create namespace traefik --dry-run=client -o yaml | kubectl apply -f -
```

---

### Option A: Zero-Build via ConfigMap (Schnellste Methode)

Mit Kustomize kannst du die Seiten direkt aus dem Ordner in den Cluster deployen, **ohne** ein eigenes Docker-Image bauen und in eine Registry pushen zu müssen:

```bash
kubectl apply -k k8s/
```

Alternativ kannst du auch die vorbereitete `configmap-deployment.yaml` anwenden:
```bash
# 1. ConfigMap mit den HTML/CSS-Dateien aus src/ erstellen:
kubectl create configmap kubiverse-error-pages-html \
  --from-file=src/ \
  --from-file=css=src/css/style.css \
  --namespace traefik --dry-run=client -o yaml | kubectl apply -f -

# 2. Deployment, Service und Middleware anwenden:
kubectl apply -f k8s/configmap-deployment.yaml
```

---

### Option B: Eigenes Docker-Image (Klassische Methode)

1. **Image bauen und in deine Registry pushen:**
   ```bash
   docker build -t meine-registry.de/fms/kubiverse-error-pages:v1.0.0 .
   docker push meine-registry.de/fms/kubiverse-error-pages:v1.0.0
   ```

2. **Image-Name in `k8s/deployment.yaml` eintragen:**
   ```yaml
   containers:
     - name: error-pages
       image: meine-registry.de/fms/kubiverse-error-pages:v1.0.0
   ```

3. **Manifeste anwenden:**
   ```bash
   kubectl apply -f k8s/deployment.yaml
   kubectl apply -f k8s/service.yaml
   kubectl apply -f k8s/traefik-middleware.yaml
   ```

---

## ⚙️ Traefik `values.yaml` Konfiguration

Du verwaltest Traefik bereits über eine `values.yaml` (z. B. via Helm oder ArgoCD). Hier sind die Schritte, um die Middleware zu aktivieren:

### 1. Globale Einbindung in `values.yaml` (Für ALLE Routen)

Öffne deine Traefik `values.yaml` und ergänze den Abschnitt `ports`:

```yaml
# ==============================================================================
# In deiner Traefik values.yaml ergänzen:
# ==============================================================================

ports:
  web:
    # Optional: Leitet unverschlüsselte HTTP-Anfragen auf HTTPS um
    redirectTo:
      port: websecure
  websecure:
    # Syntax: <namespace>-<middlewareName>@kubernetescrd
    middlewares:
      - traefik-kubiverse-error-pages@kubernetescrd
```

> **Wichtig zum Format:**
> Traefik referenziert Middleware-CRDs nach dem Muster `<namespace>-<name>@kubernetescrd`.
> Wenn deine Middleware im Namespace `traefik` mit dem Namen `kubiverse-error-pages` angelegt wurde, lautet der Name exakt:
> `traefik-kubiverse-error-pages@kubernetescrd`

#### Alternative über Traefik CLI-Argumente (`additionalArguments`):
Falls deine Helm-Chart-Version `ports.websecure.middlewares` nicht unterstützt, kannst du stattdessen folgendes in die `values.yaml` eintragen:

```yaml
additionalArguments:
  - "--entrypoints.websecure.http.middlewares=traefik-kubiverse-error-pages@kubernetescrd"
  - "--entrypoints.web.http.middlewares=traefik-kubiverse-error-pages@kubernetescrd"
```

Aktualisiere Traefik anschließend mit Helm:
```bash
helm upgrade --install traefik traefik/traefik -n traefik -f values.yaml
```

---

### 2. Einbindung pro Ingress / IngressRoute

Möchtest du die Fehlerseiten nicht global, sondern nur für bestimmte Anwendungen aktivieren, verwende eine der folgenden Methoden:

#### Für Traefik `IngressRoute`:
```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: meine-anwendung
  namespace: mein-namespace
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`portal.kubiverse.local`)
      kind: Rule
      services:
        - name: meine-anwendung-svc
          port: 80
      middlewares:
        - name: kubiverse-error-pages
          namespace: traefik
```

#### Für Standard Kubernetes `Ingress`:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: meine-anwendung
  namespace: mein-namespace
  annotations:
    kubernetes.io/ingress.class: "traefik"
    traefik.ingress.kubernetes.io/router.middlewares: traefik-kubiverse-error-pages@kubernetescrd
spec:
  rules:
    - host: portal.kubiverse.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: meine-anwendung-svc
                port:
                  number: 80
```

---

## 🧪 Fehlerseiten testen & verifizieren

1. **Prüfe, ob der Pod gesund läuft:**
   ```bash
   kubectl get pods -n traefik -l app.kubernetes.io/name=kubiverse-error-pages
   ```
   *Ausgabe sollte `2/2 Running` zeigen.*

2. **Prüfe die Traefik Middleware:**
   ```bash
   kubectl get middleware -n traefik
   ```

3. **404-Fehler provozieren:**
   Rufe eine Domain auf, die über Traefik geroutet wird, aber hänge einen nicht existierenden Pfad an:
   ```bash
   curl -I https://portal.kubiverse.local/dieser-pfad-existiert-nicht-12345
   ```
   *Ergebnis:* Der HTTP-Status bleibt `404 Not Found`, aber der Antwort-Body enthält die Kubiverse 404-Fehlerseite.

4. **502-Fehler simulieren (Bad Gateway):**
   Erstelle einen Test-Service ohne laufende Pods (oder stoppe ein Deployment kurzzeitig mit `kubectl scale deployment <app> --replicas=0`). Traefik liefert sofort die Kubiverse 502-Fehlerseite aus.

---

## 🛠️ Anpassung von Texten & Branding

Alle Vorlagen befinden sich in `src/`:
- **Texte & Titel:** Öffne die gewünschte HTML-Datei (`404.html`, `502.html`, etc.) und passe den `<p class="error-description">` oder die Diagnose-Befehle an.
- **Farben & Design:** Alle Tokens liegen in `src/css/style.css`. Die Farben nutzen das Standard-HSL-Farbschema des Kubiverse (`hsl(230, 60%, 50%)` und `hsl(270, 70%, 50%)`).
- **Logo:** `src/assets/logo.svg` kann durch ein eigenes SVG ausgetauscht werden.
