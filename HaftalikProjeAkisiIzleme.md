# Ağ Tabanlı Paralel Dağıtım Sistemi - 1. Veritabanı Performans Optimizasyonu ve İzleme
**Veritabanı:** AdventureWorks2022 

---

## 1. Hafta - Veritabanı İzleme ve Performans Analizi

1. **Veritabanı Genel Bilgileri Kontrolü** - DB_NAME(), SUSER_NAME() ve SQL Server sürümü sorgulandı; sistem durumu ve giriş yapan kullanıcı bilgisi dokumente edildi.

2. **Disk Alanı ve Dosya Yönetimi** - Veritabanı dosyalarının boyutu, fiziksel konumları ve boş alanları analiz edildi; sys.master_files tablosu kullanılarak kapasite planlaması yapıldı.

3. **Tablo Boyutları ve Satır Sayıları** - En büyük 20 tablo tespit edildi; her tablonun boyutu MB cinsinden hesaplanıp, satır sayıları kayıt edildi.

4. **İndeks Kullanım Durumu** - sys.dm_db_index_usage_stats ile indekslerin arama (SEEK), tarama (SCAN) ve güncelleme sayıları analiz edildi; kullanılmayan indeksler belirlendi.

5. **Eksik İndeks Önerileri** - sys.dm_db_missing_index_details kullanılarak eksik indeksler tespit edildi; sorgu optimizasyonunda beklenen gelişim yüzdesi hesaplanıp raporlandı.

6. **İşlem Günlüğü İstatistikleri** - LOG dosyası boyutu, büyüme hızı ve Recovery Model ayarları kontrol edildi; yedekleme stratejisi gözden geçirildi.

7. **Veritabanı İstatistikleri Kontrolü** - İstatistiklerin güncellik durumu incelendi; son güncelleme tarihleri ve örnekleme bilgileri kayıt edildi.

8. **Aktif Oturum ve İşlem İzleme** - sys.dm_exec_sessions sorgulanarak; CPU zamanı, mantıksal okumalar ve yazma sayıları monitör edildi.

9. **Önbellek Başarı Oranı (Cache Hit Ratio)** - Buffer cache performansı ölçüldü; bellek kullanımı verimliliği yüzde olarak hesaplandı.

10. **Bekleme İstatistikleri ve Performans Engellentileri** - sys.dm_os_wait_stats analiz edildi; CPU, Disk ve Lock engellentileri tanımlanıp, sistem darboğazları belirlendi.

