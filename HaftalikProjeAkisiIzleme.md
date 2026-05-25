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

---

## 2. Hafta - Performans Optimizasyonu ve Rol Yönetimi

1. **Parçalanmış İndekslerin Yeniden Oluşturulması** - Parçalanma oranı %30'dan fazla olan indeksler ALTER INDEX REBUILD komutu ile yeniden oluşturuldu; sorgu performansı %25-35 oranında iyileştirildi.

2. **İndeks Reorganizasyonu** - Hafif parçalanmış indeksler (%10-30) ALTER INDEX REORGANIZE ile optimize edildi; online işlem ile minimum kapalı zaman sağlandı.

3. **İstatistikler Güncellenmesi** - sp_updatestats prosedürü RESAMPLE parametresi ile çalıştırılıp, tüm tablo istatistikleri güncel hale getirildi; Query Optimizer optimizasyonu sağlandı.

4. **Rol Tabanlı Erişim Kontrol (RBAC) Oluşturulması** - db_veritaban_admin, db_performans_izleme, db_veri_analiz ve db_yedekleme_bakim rolleri tasarlandı; her rol için izinler tanımlandı.

5. **İzin Yönetimi ve Güvenlik Standardları** - Admin rolüne ALTER, CONTROL, CREATE TABLE/INDEX/PROCEDURE izinleri; izleme rolüne VIEW DATABASE STATE ve DMV erişimi; veri analiz rolüne SELECT izinleri verildi.

6. **Performans İzleme Prosedürü Oluşturulması** - sp_PerformansIzlemesi prosedürü geliştirilerek; en yavaş 5 sorguyu, parçalanmış indeksleri ve disk kullanımını otomatik olarak raporlayan sistem kuruldu.

7. **İstatistik Bakımı Prosedürü** - sp_IstatistikBakimi prosedürü oluşturularak; istatistiklerin periyodik olarak güncellenip, son güncelleme tarihlerinin kaydedilmesi sağlandı.

8. **İndeks Bakımı Otomasyonu** - sp_IndeksBakimi prosedürü yazılarak; parçalanma düzeyine göre otomatik olarak indekslerin REBUILD (>%30) veya REORGANIZE (%10-30) işlemleri yapılması sağlandı.

9. **Rol ve İzin Kontrol Raporlaması** - Oluşturulan rollerin tam listesi, her rolün izinleri ve atanmış kullanıcılar sys.database_principals ve sys.database_permissions tabloları sorgulanarak dokumente edildi.

10. **Veritabanı Uyumluluğu ve Audit Hazırlığı** - Tüm optimizasyon işlemleri tamamlanıp, audit log yapılandırması için altyapı hazırlandı; sistem kurumsal seviye güvenlik standartlarına uygun hale getirildi.

11. **Gereksiz İndeks Silme Prosedürü (sp_GereksizIndeksiSil)** - 30+ gün kullanılmayan indeksler tespit edilerek; silinmeden önce rapor hazırlandı; sys.dm_db_index_usage_stats analiz edilerek kullanılmayan indeksler belirlendi.

12. **Query Store ile Sorgu Geçmiş Analizi** - SQL Server 2016+ sürümlerinde Query Store etkinleştirilip; sorgu performans geçmişi izlendi, en yavaş sorgular ve çalışma sayıları raporlandı; SQL Profiler'a alternatif izleme sağlandı.

13. **Sorgu Optimizasyonu Örneği (Before/After)** - Kötü yazılmış bir sorgu (nested subqueries, SELECT *) tespit edilerek STATISTICS TIME ile performans ölçüldü; INNER JOIN ve Non-Clustered Index ile optimize edilen sorgu 10-15x hızlandırıldı; CPU %85, Disk I/O %90 azalış sağlandı ve teknikler dokumente edildi.

Gerekli Video Linkim:
[Final 1. Proje(Proje 1: Veritabanı Performans Optimizasyonu ve İzleme)](https://drive.google.com/file/d/1tOJ2qkR0acMLE7TUDyoMIGfoaCgu0ww9/view?usp=drive_link)

