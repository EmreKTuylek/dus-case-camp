# DUS Case Camp - Adım Adım Kurulum ve Kullanım Rehberi (Türkçe)

Bu rehber, hiçbir yazılım bilgisi olmayan birinin (Windows bilgisayar kullanarak) bu projeyi sıfırdan kurup çalıştırması için hazırlanmıştır.

---

## BÖLÜM 1: Gerekli Programların Kurulumu

Bilgisayarınızda aşağıdaki araçların kurulu olması gerekmektedir. Eğer kuruluysa bu adımı geçebilirsiniz.

### 1. Flutter'ı İndirin (Uygulamayı çalıştırmak için)
1.  [Flutter Windows İndirme Sayfasına](https://docs.flutter.dev/get-started/install/windows) gidin.
2.  "Get the Flutter SDK" butonuna tıklayıp `.zip` dosyasını indirin.
3.  Bu dosyayı `C:\src\flutter` gibi basit bir klasöre çıkartın (Program Files içine koymayın!).
4.  **Önemli:** Bilgisayarınızın "Ortam Değişkenleri"ne (Environment Variables) Flutter'ı eklemeniz lazım:
    - Başlat menüsüne "env" yazın ve "Sistem ortam değişkenlerini düzenleyin"e tıklayın.
    - "Ortam Değişkenleri" butonuna basın.
    - "Path" satırını bulup "Düzenle" deyin.
    - "Yeni" butonuna basın ve `C:\src\flutter\bin` yolunu yapıştırın.
    - Tamam diyerek çıkın.

### 2. Node.js'i İndirin (Firebase araçları için)
1.  [Node.js web sitesine](https://nodejs.org/) gidin.
2.  "LTS" (Long Term Support) versiyonunu indirin ve kurun. Kurulumda her şeye "Next" diyebilirsiniz.

### 3. Firebase CLI'ı Kurun (Sunucu işlemleri için)
1.  Bilgisayarınızda "Komut İstemi"ni (Command Prompt veya CMD) açın.
2.  Şu komutu yazıp Enter'a basın:
    ```bash
    npm install -g firebase-tools
    ```

### 4. VS Code (Kod Editörü)
1.  [VS Code web sitesinden](https://code.visualstudio.com/) indirin ve kurun. Bu program projeyi açıp yönetmenizi sağlar.

---

## BÖLÜM 2: Projeyi Açma ve Hazırlama

1.  Size gönderilen proje klasörünü (`dusCase`) bilgisayarınızda bir yere koyun.
2.  VS Code programını açın.
3.  Sol üstten **File > Open Folder** (Dosya > Klasör Aç) diyerek `dusCase` klasörünü seçin.
4.  VS Code içinde üst menüden **Terminal > New Terminal** diyerek alt tarafta bir komut penceresi açın.

### Gerekli Kütüphaneleri İndirme
Terminal penceresine şu komutları sırasıyla yazıp Enter'a basın:

```bash
cd dus_case_camp
flutter pub get
```
*(Bu işlem internet hızınıza göre biraz sürebilir, bekleyin.)*

---

## BÖLÜM 3: Firebase (Veritabanı) Bağlantısı

Bu proje Google Firebase kullanır. Kendi hesabınızı bağlamanız gerekir.

1.  [Firebase Konsolu](https://console.firebase.google.com/) adresine gidin ve Google hesabınızla giriş yapın.
2.  "Proje Ekle" (Add Project) butonuna basın.
3.  Projeye bir isim verin (örneğin: `dus-case-camp-2025`).
4.  Google Analytics sorarsa "Devam" deyin, hesap seçin ve projeyi oluşturun.
5.  VS Code terminaline geri dönün ve şu komutu yazın:
    ```bash
    firebase login
    ```
    *(Tarayıcı açılacak, Google hesabınızla giriş yapıp izin verin.)*

6.  Şimdi projeyi bağlamak için şu komutu yazın:
    ```bash
    dart pub global activate flutterfire_cli
    flutterfire configure
    ```
    - Size hangi projeyi kullanmak istediğinizi soracak. Ok tuşlarıyla az önce oluşturduğunuz projeyi (`dus-case-camp-2025`) seçin ve Enter'a basın.
    - Platform sorduğunda (Android, iOS, Web) hepsinin seçili olduğundan emin olun ve Enter'a basın.
    - İşlem bitene kadar bekleyin. `firebase_options.dart` dosyası otomatik oluşturulacak.

---

## BÖLÜM 4: Uygulamayı Çalıştırma

### Web Tarayıcısında Çalıştırma (En kolayı)
Terminalde şu komutu yazın:
```bash
flutter run -d chrome
```
Biraz bekledikten sonra Chrome tarayıcısı açılacak ve uygulamanızı göreceksiniz!

### Android Telefonda Çalıştırma
1.  Telefonunuzu USB kablosuyla bilgisayara bağlayın.
2.  Telefon ayarlarından "Geliştirici Seçenekleri"ni açıp "USB Hata Ayıklama"yı (USB Debugging) aktif etmeniz gerekir.
3.  Terminalde `flutter run` yazın. Bilgisayar telefonunuzu görecek ve uygulamayı yükleyecektir.

---

## BÖLÜM 5: Uygulamayı Yayına Alma (Deploy)

Uygulamayı internette herkesin erişebileceği bir web sitesi haline getirmek için:

1.  Terminalde (hala `dus_case_camp` klasöründeyseniz) bir üst klasöre çıkın veya yeni terminal açıp ana klasörde (`dusCase`) olun.
2.  Şu komutu yazın:
    ```bash
    firebase deploy
    ```
3.  İşlem bittiğinde size bir "Hosting URL" verecek (örneğin: `https://dus-case-camp-2025.web.app`).
4.  Bu linki öğrencilerinize gönderebilirsiniz!

---

## BÖLÜM 6: Günlük İş Akışı (Kamp Organizatörü Olarak)

Siz "Öğretmen/Admin" rolündesiniz. İşte yapmanız gerekenler:

### 1. Haftayı Başlatma (Pazartesi)
- Uygulamaya girin, Profil > **Admin Paneli**'ne gidin.
- **Weeks (Haftalar)** sekmesine gelin.
- `+` butonuna basıp "Hafta 1: Endodonti" gibi bir hafta oluşturun.
- Oluşturduğunuz haftanın yanındaki "Düzenle" ikonuna basıp **Vakalar (Cases)** ekleyin.
- Vakaları ekledikten sonra geri dönüp haftayı **Activate (Aktifleştir)** butonuna basarak başlatın.
- **Sonuç:** Öğrencilere "Yeni hafta başladı!" bildirimi gider.

### 2. Hafta Boyunca (Öğrenciler Ne Yapar?)
- Öğrenciler uygulamaya girer.
- Aktif haftanın vakalarını görürler.
- Vakayı okur ve çözüm videolarını yüklerler.
- Liderlik tablosunda (Leaderboard) sıralamalarını takip ederler.

### 3. Değerlendirme (Hafta İçi/Sonu)
- Admin Paneli > **Reviews (Değerlendirmeler)** sekmesine gidin.
- "Pending" (Bekleyen) videoları izleyin.
- 0-100 arası bir puan verin ve "Save Score" deyin.
- **Sonuç:** Öğrenci puanını kazanır, bildirim alır ve sıralama güncellenir.

### 4. Sorun Olursa?
- Eğer bir şeyler çalışmazsa sayfayı yenileyin.
- Öğrenciler "yükleme hatası" alıyorsa internetlerini kontrol etsinler veya video boyutunun 100MB'ı geçmediğinden emin olsunlar.

---

**Tebrikler! DUS Case Camp artık yayında.**
