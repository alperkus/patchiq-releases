#!/bin/bash
# PatchIQ — tek seferlik saha guncellemesi (wget ile).
#
# NEDEN VAR
# Sahadan (26 Agu 2026): tarayicidan paket secilemiyor. Sebebi bulundu ve
# duzeltildi ama duzeltme paketin ICINDE; kutuya ulastirmak icin once bir kez
# tarayici disindan yuklemek gerekiyor. Bu betik onu yapar ve BIR KEZ gerekir:
# 0.3.8'den sonra guncelleme kanali devreye girer, kutu kendi indirir.
#
# NE YAPAR
#   1. Paketi public yayin deposundan indirir (kimlik/belirtec GEREKMEZ)
#   2. sha256'yi BEKLENEN degerle karsilastirir
#   3. Ajanin spool dizinine koyar ve tetigi yazar
#   4. Ajan paketi alir, IMZAYI KENDI DOGRULAR ve kurar
#
# GUVEN SINIRI — ACIKCA
# Bu betik root olarak kosar ve IMZALI DEGILDIR. Ama kurdugu paket imzalidir:
# ajan Ed25519 imzasini kendi gomulu anahtariyla bastan dogrular. Yani bu
# betik "neyin kurulacagina" karar veremez; yalnizca dosyayi yerine koyar.
# Yine de indirmeden once icerigini okuyun.
#
# GERI ALMA
# Ajan kurulumdan once veritabanini yedekler; saglik kontrolu duserse eski
# surume kendiliginden doner (updater.py).

set -euo pipefail

SURUM="0.3.8-beta"
DOSYA="patchiq-${SURUM}-update.tar.gz"
ADRES="https://github.com/alperkus/patchiq-releases/releases/download/v${SURUM}/${DOSYA}"
BEKLENEN_SHA="25902f14b224e9abb4bc0e52dbc7ae622949dc523f3a7bf5621685867111af32"

oku() { printf '  %s\n' "$1"; }
dur() { printf '\nHATA: %s\n' "$1" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || dur "root gerekir:  sudo bash $0"

echo "PatchIQ saha guncellemesi -> ${SURUM}"
echo

# ── 1) Ajanin yapilandirmasini bul ────────────────────────────────────────
# Spool yolu TAHMIN EDILMEZ: ajanin kendi env dosyasindan okunur. Yanlis
# dizine dosya birakmak, hicbir sey olmamasi demektir.
ENV_DOSYA="$(ls -1 /etc/*/updater.env 2>/dev/null | head -1 || true)"
[ -n "$ENV_DOSYA" ] || dur "guncelleme ajani yapilandirmasi bulunamadi (/etc/*/updater.env).
       Ajan kurulu degilse once kurulum sihirbazini calistirin."
oku "ajan yapilandirmasi: $ENV_DOSYA"

# shellcheck disable=SC1090
SPOOL="$(. "$ENV_DOSYA"; printf '%s' "${UPDATER_SPOOL:-}")"
[ -n "$SPOOL" ] || dur "UPDATER_SPOOL tanimsiz ($ENV_DOSYA)"
[ -d "$SPOOL/gelen" ] || dur "spool dizini yok: $SPOOL/gelen"
oku "spool: $SPOOL"

# Suren bir guncellemenin ustune ikincisi binmesin.
if [ -f "$SPOOL/durum.json" ] && grep -q '"bitti_mi": *false' "$SPOOL/durum.json" 2>/dev/null; then
  dur "bir guncelleme hala suruyor; bitmesini bekleyin"
fi

# ── 2) Indir ──────────────────────────────────────────────────────────────
GECICI="$(mktemp -d)"
trap 'rm -rf "$GECICI"' EXIT
oku "indiriliyor: $ADRES"
wget --quiet --show-progress -O "$GECICI/$DOSYA" "$ADRES" \
  || dur "indirme basarisiz. Kutunun disariya cikisi yoksa paketi baska bir
       makineye indirip scp ile buraya kopyalayin ve ADRES yerine yerel
       yolu kullanin."

# ── 3) Ozeti dogrula ──────────────────────────────────────────────────────
INEN_SHA="$(sha256sum "$GECICI/$DOSYA" | cut -d' ' -f1)"
if [ "$INEN_SHA" != "$BEKLENEN_SHA" ]; then
  dur "ozet TUTMUYOR — paket bozuk ya da degistirilmis, KURULMADI.
       beklenen: $BEKLENEN_SHA
       inen    : $INEN_SHA"
fi
oku "sha256 dogrulandi"

# ── 4) Yerine koy, SONRA tetigi yaz ───────────────────────────────────────
# SIRA ONEMLI: ajan tetigi gorunce paketi arar. Ters sira, yarim dosyanin
# dogrulanmaya calisilmasi demek olurdu.
HEDEF="$SPOOL/gelen/${BEKLENEN_SHA}.tar.gz"
ISTEK="$SPOOL/gelen/${BEKLENEN_SHA}.istek"
[ -e "$ISTEK" ] && dur "bu paket icin tetik zaten var: $ISTEK
       Ajan islemis olabilir; Ayarlar -> Guncelleme ekranina bakin."

install -m 0640 "$GECICI/$DOSYA" "$HEDEF"
oku "paket yerinde: $HEDEF"

printf '{"sha256":"%s","aktor":"saha-betigi","surum_hedef":"%s","istendi":"%s"}\n' \
  "$BEKLENEN_SHA" "$SURUM" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$ISTEK.tmp"
mv "$ISTEK.tmp" "$ISTEK"
oku "tetik yazildi"

echo
echo "Tamam. Ajan paketi birkac saniye icinde alir."
echo "Ilerlemeyi Ayarlar -> Guncelleme ekranindan izleyin;"
echo "konteynerler yeniden baslarken arayuz kisa sure erisilemez olabilir."
