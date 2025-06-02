# RHOAI GitOps Otomasyon Yapısı

Bu yapı, kullanıcıdan gelen `user-request.json` dosyasına göre GitHub Actions ile otomatik olarak `overlays/<username>` dizinlerini üretir.

## Yapı

- `base/` altında şablon kaynaklar (namespace, workbench, model)
- `scripts/generate_overlay.sh` → JSON'dan overlay üretir
- `.github/workflows/apply.yaml` → GitHub Actions workflow'u
- `user-requests/` → Kullanıcıdan gelen taleplerin konduğu dizin

## Kullanım

1. Kullanıcı `user-requests/ahmet.json` gibi bir JSON dosyası push eder.
2. GitHub Actions tetiklenir ve `scripts/generate_overlay.sh` çalışır.
3. Yeni overlay oluşturulur ve Git'e commit edilir.
4. ArgoCD bu yeni dizini senkronize eder.
