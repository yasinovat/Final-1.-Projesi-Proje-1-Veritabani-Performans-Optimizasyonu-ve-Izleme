/*

AĞ TABANLI PARALEL DAĞITIM SİSTEMİ PROJESİ
1. Veritabanı Performans Optimizasyonu ve İzleme
AdventureWorks2022 

*/

USE AdventureWorks2022;
GO

-- 1. HAFTA - VERİTABANI İZLEME VE PERFORMANS ANALİZİ
-- 1. Hafta Hedefleri:
-- • Veritabanı genel durumunun kontrol edilmesi
-- • Performans metrikleri analiz edilmesi
-- • Yavaş sorguların belirlenmesi
-- • İndeks kullanım durumu incelemesi
-- • Disk alanı yönetimi değerlendirilmesi

-- ------------------------------ 1. HAFTA: BAŞLANGIÇ ------------------------------

PRINT '1. HAFTA - VERİTABANI İZLEME VE PERFORMANS ANALİZİ';
GO

-- 1.1. Veritabanı Genel Bilgileri
-- Amaç: Veritabanının genel durumunu öğrenme
PRINT CHAR(10) + '1.1. VERİTABANI GENEL BİLGİLERİ';
SELECT 
    DB_NAME() AS [Veritabanı Adı],
    SUSER_NAME() AS [Giriş Yapan Kullanıcı],
    GETDATE() AS [Güncel Tarih Saat],
    @@VERSION AS [SQL Server Sürümü];
GO

-- 1.2. Veritabanı Dosya Bilgileri ve Disk Alanı Yönetimi
-- Amaç: Disk alanı kullanımını kontrol etme
PRINT CHAR(10) + '1.2. VERİTABANI DOSYA VE DISK ALANI YÖNETİMİ';
SELECT 
    mf.[file_id],
    mf.[name] AS [Dosya Adı],
    mf.[physical_name] AS [Fiziksel Yol],
    mf.[type_desc] AS [Dosya Tipi],
    CONVERT(DECIMAL(10,2), mf.[size] * 8 / 1024) AS [Boyut_MB],
    CONVERT(DECIMAL(10,2), (mf.[size] - FILEPROPERTY(mf.[name], 'SpaceUsed')) * 8 / 1024) AS [Boş_Alan_MB]
FROM sys.master_files mf
WHERE database_id = DB_ID()
ORDER BY mf.[file_id];
GO

-- 1.3. Tablo Boyutları ve Satır Sayıları
-- Amaç: En büyük tabloları belirlemek
PRINT CHAR(10) + '1.3. TABLO BOYUTLARI VE SATIR SAYILARI';
SELECT TOP 20
    t.[name] AS [Tablo Adı],
    i.[rows] AS [Satır Sayısı],
    CONVERT(DECIMAL(10,2), (SUM(a.[total_pages]) * 8) / 1024) AS [Toplam_Boyut_MB],
    CONVERT(DECIMAL(10,2), (SUM(a.[used_pages]) * 8) / 1024) AS [Kullanılan_MB]
FROM sys.tables t
INNER JOIN sys.indexes i ON t.[object_id] = i.[object_id]
INNER JOIN sys.allocation_units a ON i.[container_id] = a.[container_id]
WHERE t.[is_ms_shipped] = 0
GROUP BY t.[name], i.[rows]
ORDER BY SUM(a.[total_pages]) DESC;
GO

-- 1.4. İndeks Kullanım Durumu Analizi
-- Amaç: Kullanılan ve kullanılmayan indeksleri belirlemek
PRINT CHAR(10) + '1.4. İNDEKS KULLANIM DURUMU ANALİZİ';
SELECT 
    OBJECT_NAME(ius.[object_id]) AS [Tablo Adı],
    i.[name] AS [İndeks Adı],
    ius.[user_seeks] AS [Arama Sayısı],
    ius.[user_scans] AS [Tarama Sayısı],
    ius.[user_lookups] AS [Arama Sayısı_2],
    ius.[user_updates] AS [Güncelleme Sayısı],
    (ius.[user_seeks] + ius.[user_scans] + ius.[user_lookups]) AS [Toplam_Okuma]
FROM sys.dm_db_index_usage_stats ius
INNER JOIN sys.indexes i ON ius.[object_id] = i.[object_id] AND ius.[index_id] = i.[index_id]
WHERE database_id = DB_ID() AND OBJECTPROPERTY(ius.[object_id], 'IsUserTable') = 1
ORDER BY (ius.[user_seeks] + ius.[user_scans] + ius.[user_lookups]) DESC;
GO

-- 1.5. Eksik İndeksler - Potansiyel Performans Sorunları
-- Amaç: Eksik indeksleri bulup performans iyileştirmesi yapma
PRINT CHAR(10) + '1.5. EKSİK İNDEKSLER - PERFORMANS OPTİMİZASYONU FIRSATLARI';
SELECT 
    mid.[equality_columns],
    mid.[inequality_columns],
    mid.[included_columns],
    mid.[user_seeks],
    mid.[user_scans],
    mid.[user_lookups],
    mid.[user_updates],
    mid.[migs_user_seeks] * mid.[avg_total_user_cost] * (mid.[user_seeks] + mid.[user_scans] + mid.[user_lookups]) AS [Beklenen_Gelişim]
FROM sys.dm_db_missing_index_details mid
INNER JOIN sys.dm_db_missing_index_groups mig ON mid.[index_handle] = mig.[index_handle]
INNER JOIN sys.dm_db_missing_index_groups_stats migs ON mig.[index_group_id] = migs.[index_group_id]
WHERE database_id = DB_ID()
ORDER BY [Beklenen_Gelişim] DESC;
GO

-- 1.6. İşlem Günlüğü Boyutu ve Yönetimi
-- Amaç: İşlem günlüğü durumunu ve kullanım hızını kontrol etme
PRINT CHAR(10) + '1.6. İŞLEM GÜNLÜĞÜ BOYUTU VE YÖNETIMI';
SELECT 
    name,
    type_desc AS [Tür],
    CONVERT(DECIMAL(10,2), size * 8 / 1024) AS [Boyut_MB],
    max_size,
    growth,
    growth_desc AS [Büyüme_Tipi]
FROM sys.database_files
WHERE type_desc = 'LOG';
GO

-- 1.7. Veritabanı İstatistikleri Kontrol
-- Amaç: İstatistiklerin güncellik durumunu kontrol etme
PRINT CHAR(10) + '1.7. VERİTABANI İSTATİSTİKLERİ DURUMU';
SELECT TOP 20
    OBJECT_NAME(s.[object_id]) AS [Tablo Adı],
    s.[name] AS [İstatistik Adı],
    s.[stats_id],
    sp.[last_updated] AS [Son_Güncelleme_Tarihi],
    sp.[rows] AS [Satır Sayısı],
    sp.[rows_sampled] AS [Örnek_Satır_Sayısı],
    DATEDIFF(DAY, sp.[last_updated], GETDATE()) AS [Güncelleme_Gün_Fark]
FROM sys.stats s
CROSS APPLY sys.dm_db_stats_properties(s.[object_id], s.[stats_id]) sp
WHERE OBJECTPROPERTY(s.[object_id], 'IsUserTable') = 1
ORDER BY sp.[last_updated] ASC;
GO

-- 1.8. İşlem Kilidi ve Engelleme Analizi
-- Amaç: Aktif işlemlerdeki kilitleme durumunu kontrol etme
PRINT CHAR(10) + '1.8. OTURUM VE IŞLEM BİLGİLERİ';
SELECT 
    session_id AS [Oturum ID],
    host_process_id AS [İşlem ID],
    login_name AS [Giriş Adı],
    nt_user_name AS [Windows Kullanıcı],
    status AS [Durum],
    cpu_time AS [CPU_Zamanı_ms],
    logical_reads AS [Mantıksal_Okumalar],
    writes AS [Yazma_Sayısı]
FROM sys.dm_exec_sessions
WHERE session_id > 50
ORDER BY cpu_time DESC;
GO

-- 1.9. Cache Hit Ratio (Önbellek Başarı Oranı)
-- Amaç: Bellek verimliliğini kontrol etme
PRINT CHAR(10) + '1.9. CACHE HİT RATIO (ÖNBELLEK BAŞARI ORANI)';
SELECT 
    'Buffer Cache' AS [Önbellek Tipi],
    CONVERT(DECIMAL(5,2), 100.0 * SUM(CASE WHEN bd.[database_id] <> 32767 THEN 1 ELSE 0 END) 
    / COUNT(*)) AS [Hit_Ratio_%]
FROM sys.dm_os_buffer_descriptors bd
WHERE bd.[database_id] = DB_ID() OR bd.[database_id] = 32767;
GO

-- 1.10. Veritabanı Bekleme İstatistikleri
-- Amaç: Sistem performans engellentilerini belirlemek
PRINT CHAR(10) + '1.10. BEKLEME İSTATİSTİKLERİ - PERFORMANS ENGELLENTILERI';
SELECT TOP 10
    os.[wait_type],
    os.[wait_time_ms],
    os.[signal_wait_time_ms],
    os.[waiting_tasks_count],
    CONVERT(DECIMAL(10,2), os.[wait_time_ms] / NULLIF(os.[waiting_tasks_count], 0)) AS [Ort_Bekleme_ms]
FROM sys.dm_os_wait_stats os
WHERE os.[wait_type] NOT IN ('SLEEP_TASK', 'BROKER_EVENTHANDLER', 'REQUEST_FOR_DEADLOCK_SEARCH',
    'LOGMGR_QUEUE', 'ONDEMAND_TASK_QUEUE', 'BROKER_TRANSMITTER')
ORDER BY os.[wait_time_ms] DESC;
GO

-- 1.11. En Yavaş Sorgular - DMV ile Analiz
-- Amaç: Uzun süreli sorguları belirleyip optimize etmek
PRINT CHAR(10) + '1.11. EN YAVAS SORGULAR - SORGU OPTİMİZASYON FURSATLARI';
SELECT TOP 10
    CONVERT(DECIMAL(10,2), qs.[total_elapsed_time] / 1000000) AS [Toplam_Süre_Saniye],
    qs.[execution_count] AS [Çalıştırılma_Sayısı],
    CONVERT(DECIMAL(10,2), qs.[total_elapsed_time] / 1000000 / NULLIF(qs.[execution_count], 0)) AS [Ort_Süre_Saniye],
    qs.[total_worker_time] / 1000000 AS [CPU_Zamanı_Saniye],
    SUBSTRING(st.[text], 1, 100) AS [Sorgu_Metni]
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.[sql_handle]) st
ORDER BY qs.[total_elapsed_time] DESC;
GO

-- 1.12. Fragment Analizi - İndeks Parçalanması
-- Amaç: Parçalanmış indeksleri belirlemek
PRINT CHAR(10) + '1.12. İNDEKS PARÇALANMA ANALİZİ';
SELECT TOP 20
    OBJECT_NAME(ips.[object_id]) AS [Tablo_Adı],
    i.[name] AS [İndeks_Adı],
    CONVERT(DECIMAL(5,2), ips.[avg_fragmentation_in_percent]) AS [Parçalanma_%],
    ips.[page_count] AS [Sayfa_Sayısı]
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.[object_id] = i.[object_id] AND ips.[index_id] = i.[index_id]
WHERE ips.[avg_fragmentation_in_percent] > 10 AND ips.[page_count] > 1000
ORDER BY ips.[avg_fragmentation_in_percent] DESC;
GO


