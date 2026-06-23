# AwehPay Backend — Elastic Beanstalk Deployment

The backend is a stateless Node/Express API that talks to Firebase (Auth + Firestore)
and Paystack. It is deployed to **AWS Elastic Beanstalk**. CI auto-deploys the
`backend/` folder to Beanstalk on every push to `main`
(see [`.github/workflows/deploy.yaml`](../.github/workflows/deploy.yaml)).

---

## 1. Credentials & config (how secrets are loaded)

`server.js` loads the Firebase service account in a backwards-compatible way:

| Environment | Variable | Value |
|---|---|---|
| **Cloud (Beanstalk)** | `FIREBASE_SERVICE_ACCOUNT_B64` | **base64** of the service-account JSON file (preferred — survives EB transport intact) |
| **Local dev** | `GOOGLE_APPLICATION_CREDENTIALS` | file path to the JSON key on disk |

> Pasting the **raw** JSON into an EB environment property corrupts the private key's
> newlines and fails with `Failed to parse private key: Only 8, 16, 24, or 32 bits
> supported`. Use the base64 variable instead. Generate it on Windows PowerShell:
>
> ```powershell
> [Convert]::ToBase64String([IO.File]::ReadAllBytes("awehpay-firebase-adminsdk-fbsvc-bf97993378.json"))
> ```
>
> (macOS/Linux: `base64 -w0 awehpay-firebase-adminsdk-...json`.) Copy the single-line
> output and set it as `FIREBASE_SERVICE_ACCOUNT_B64`.

Other required env vars:

| Variable | Notes |
|---|---|
| `PAYSTACK_SECRET_KEY` | Paystack secret key (use the **live** key in prod) |
| `PORT` | Auto-set by Beanstalk (8080). Local falls back to 5000. Do **not** set manually in EB. |

> The service-account JSON file is gitignored and excluded from the CI bundle. It is
> never committed and never baked into the deployment artifact.

---

## 2. One-time AWS setup

### a. Create the Elastic Beanstalk application + environment
1. EB console → **Create application**.
   - Application name: `awehpay-backend` (remember this — it's a GitHub secret later).
   - Platform: **Node.js** on **Amazon Linux 2023**.
   - Environment name: e.g. `awehpay-backend-prod` (also a GitHub secret).
   - Environment type: **Load balanced** (needed for HTTPS).
2. Upload any small zip to create it (CI will replace it), or use the sample app.

### b. Set environment properties
EB console → your environment → **Configuration → Updates, monitoring, and logging →
Environment properties** (or **Software**). Add:
- `FIREBASE_SERVICE_ACCOUNT_B64` = the base64 string generated above (single line).
- `PAYSTACK_SECRET_KEY` = your Paystack secret key.

Apply. The environment restarts with the new config.

> **More secure option (recommended for prod):** instead of pasting the JSON as a plain
> env property, store it in **AWS Secrets Manager**, grant the EB instance role
> `secretsmanager:GetSecretValue`, and load it at boot. The current code reads it straight
> from `FIREBASE_SERVICE_ACCOUNT`, so to use Secrets Manager you'd fetch the secret in
> `server.js` and assign it to that var before `loadServiceAccount()` runs. Start with the
> env property to get deploying; harden to Secrets Manager after.

### c. Health check
The included [`.ebextensions/options.config`](.ebextensions/options.config) points the load
balancer health check at `/health` and enables enhanced health. Nothing to do manually.

### d. HTTPS + domain (prod)
1. Request/import a cert for `api.awehpay.co.za` in **AWS Certificate Manager** (same region).
2. EB → Configuration → **Load balancer** → add an **HTTPS:443** listener using that cert.
3. Point `api.awehpay.co.za` (Route 53 or your DNS) at the EB load balancer.
4. In Paystack, set the webhook URL to `https://api.awehpay.co.za/webhooks/paystack`.

### e. IAM user for CI
1. IAM → create a user, e.g. `github-actions-eb-deploy`, **programmatic access**.
2. Attach a policy allowing EB deploys + S3 (EB stores versions in S3). Simplest start:
   `AdministratorAccess-AWSElasticBeanstalk` (managed), or scope down to
   `elasticbeanstalk:*`, `s3:*` on the EB bucket, `autoscaling`, `cloudformation`, `ec2`,
   `elasticloadbalancing` as the EB docs describe.
3. Save the **Access key ID** and **Secret access key**.

---

## 3. GitHub repo secrets

Repo → **Settings → Secrets and variables → Actions → New repository secret**:

| Secret | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | from the CI IAM user |
| `AWS_SECRET_ACCESS_KEY` | from the CI IAM user |
| `AWS_REGION` | e.g. `eu-west-1` (whatever region your EB env is in) |
| `EB_APPLICATION_NAME` | e.g. `awehpay-backend` |
| `EB_ENVIRONMENT_NAME` | e.g. `awehpay-backend-prod` |

---

## 4. How a deploy happens

- Push to `main` that touches `backend/**` → the workflow zips the `backend/` folder
  (excluding `node_modules`, `.env`, and the service-account JSON), uploads it as a new EB
  application version, and deploys it to the environment.
- You can also trigger it manually: Actions tab → **Deploy backend to Elastic Beanstalk**
  → **Run workflow**.
- Beanstalk runs `npm install` then `node server.js` (via the `Procfile`) on port 8080.

---

## 5. Build the mobile app against prod

```bash
flutter build appbundle --dart-define=AWEHPAY_API_BASE_URL=https://api.awehpay.co.za
```

(Use the same `--dart-define` for `flutter build ipa` on iOS.)
