# Production Security Checklist

- [ ] `APP_DEBUG=false`.
- [ ] HTTPS enabled for API and frontend.
- [ ] Secure database credentials configured.
- [ ] No `.env` file committed.
- [ ] Production OAuth credentials configured.
- [ ] OAuth redirect URIs use production HTTPS domains.
- [ ] CORS restricted to real frontend domains.
- [ ] File upload limits enabled at Laravel, PHP, and web server layers.
- [ ] Public storage permissions checked.
- [ ] Rate limiting enabled.
- [ ] Backups configured and restore tested.
- [ ] Logs monitored.
- [ ] Admin/moderation workflow planned.
- [ ] Privacy policy prepared.
- [ ] Terms of service prepared.
- [ ] Malware scanning considered for uploaded media.
- [ ] Account deletion workflow reviewed legally and technically.
