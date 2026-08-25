# PatchIQ — yayın kanalı / release channel

Bu depo **yalnız yayın dosyalarını** taşır: `manifest.json` ve imzalı
güncelleme paketleri. Ürünün kaynak kodu burada değildir ve burada olmayacaktır.

## Neden herkese açık

Paketler **Ed25519 ile imzalıdır** ve kutu her paketi kendi gömülü açık
anahtarıyla doğrular. Doğrulama, dosyanın nereden geldiğine bakmaz: kanaldan
inen paket ile elle yüklenen paket aynı kapıdan geçer. Bu yüzden kanalın
herkese açık olması bir güven sorunu doğurmaz — kanal güvenilmez, imza
güvenilir.

Ayrıca kutu geçerli bir lisans olmadan çalışmaz; paketi indirmek onu
kullanılabilir yapmaz.

Depo herkese açık olduğu için kutulara **hiçbir erişim belirteci konmaz**.
Belirteç koymak, müşteri kutusuna kaynak deposuna okuma erişimi vermek olurdu.

## manifest.json

Kutu bu dosyayı okur ve "daha yeni bir sürüm var mı" sorusunu yanıtlar.
Her kayıt şunları taşır: `surum`, `yayim`, `asgari` (yükseltilebilecek en eski
kurulu sürüm), `sha256`, `paket_adresi`, isteğe bağlı `not_adresi` ve `boyut`.

Kurulum **otomatik değildir**. Kutu kendiliğinden bakar, kendiliğinden kurmaz.
