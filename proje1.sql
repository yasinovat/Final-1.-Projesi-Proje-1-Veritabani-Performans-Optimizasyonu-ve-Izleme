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


-- ================================================================================
-- 2. HAFTA - PERFORMANS OPTİMİZASYONU VE ROL YÖNETİMİ
-- ================================================================================
-- 2. Hafta Hedefleri:
-- • Eksik indeksler oluşturulması
-- • Parçalanmış indeksler yeniden yapılandırılması
-- • Veri yönetici rolleri tanımlanması ve izinleri ayarlanması
-- • Bakım işleri planlanması
-- • Veritabanı izleme prosedürleri oluşturulması

-- ------------------------------ 2. HAFTA: BAŞLANGIÇ ------------------------------

PRINT CHAR(10) + '========================================================';
PRINT '2. HAFTA - PERFORMANS OPTİMİZASYONU VE ROL YÖNETİMİ';
PRINT '========================================================';
GO

-- 2.1. İndeks Yeniden Oluşturma - Parçalanmış İndeksleri Onarma
-- Amaç: Parçalanma > 30% olan indeksleri yeniden oluşturma
PRINT CHAR(10) + '2.1. PARÇALANMIŞ İNDEKSLERİ YENİDEN OLUŞTURMA';

DECLARE @TableName NVARCHAR(128);
DECLARE @IndexName NVARCHAR(128);
DECLARE @SQL NVARCHAR(500);

DECLARE index_cursor CURSOR FOR
SELECT 
    OBJECT_NAME(ips.[object_id]) AS TableName,
    i.[name] AS IndexName
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.[object_id] = i.[object_id] AND ips.[index_id] = i.[index_id]
WHERE ips.[avg_fragmentation_in_percent] > 30 
  AND ips.[page_count] > 1000
  AND i.[index_id] > 0
  AND OBJECTPROPERTY(ips.[object_id], 'IsUserTable') = 1;

OPEN index_cursor;

FETCH NEXT FROM index_cursor INTO @TableName, @IndexName;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'ALTER INDEX [' + @IndexName + '] ON [' + @TableName + '] REBUILD;';
    PRINT 'Çalıştırılıyor: ' + @SQL;
    -- EXEC sp_executesql @SQL;
    
    FETCH NEXT FROM index_cursor INTO @TableName, @IndexName;
END;

CLOSE index_cursor;
DEALLOCATE index_cursor;

PRINT 'İndeks yeniden oluşturma işlemi tamamlandı.';
GO

-- 2.2. İndeks Reorganizasyon - Hafif Parçalanma (10-30%)
-- Amaç: Hafif parçalanmış indeksleri hızlı bir şekilde organize etme
PRINT CHAR(10) + '2.2. İNDEKS REORGANIZASYONU - HAFIF PARÇALANMA';

DECLARE @TableName2 NVARCHAR(128);
DECLARE @IndexName2 NVARCHAR(128);
DECLARE @SQL2 NVARCHAR(500);

DECLARE index_cursor2 CURSOR FOR
SELECT 
    OBJECT_NAME(ips.[object_id]) AS TableName,
    i.[name] AS IndexName
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.[object_id] = i.[object_id] AND ips.[index_id] = i.[index_id]
WHERE ips.[avg_fragmentation_in_percent] BETWEEN 10 AND 30
  AND ips.[page_count] > 1000
  AND i.[index_id] > 0
  AND OBJECTPROPERTY(ips.[object_id], 'IsUserTable') = 1;

OPEN index_cursor2;

FETCH NEXT FROM index_cursor2 INTO @TableName2, @IndexName2;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL2 = 'ALTER INDEX [' + @IndexName2 + '] ON [' + @TableName2 + '] REORGANIZE;';
    PRINT 'Çalıştırılıyor: ' + @SQL2;
    -- EXEC sp_executesql @SQL2;
    
    FETCH NEXT FROM index_cursor2 INTO @TableName2, @IndexName2;
END;

CLOSE index_cursor2;
DEALLOCATE index_cursor2;

PRINT 'İndeks reorganizasyon işlemi tamamlandı.';
GO

-- 2.3. İstatistikleri Güncelleme
-- Amaç: Sorgu optimizasyonu için istatistikleri güncel tutma
PRINT CHAR(10) + '2.3. VERİTABANI İSTATİSTİKLERİNİ GÜNCELLEME';

EXEC sp_updatestats @resample = 'RESAMPLE';
PRINT 'Tüm istatistikler başarıyla güncellendi.';
GO

-- 2.4. Veri Yönetici Rolleri Oluşturma
-- Amaç: Veritabanı yönetimi için uygun rolleri tanımlamak
PRINT CHAR(10) + '2.4. VERİ YÖNETMELERI ROLLERI OLUŞTURMA';

-- Admin Rolü
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'db_veritaban_admin' AND type = 'R')
BEGIN
    CREATE ROLE db_veritaban_admin;
    PRINT 'db_veritaban_admin rolü oluşturuldu.';
END;

-- Performans İzleme Rolü
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'db_performans_izleme' AND type = 'R')
BEGIN
    CREATE ROLE db_performans_izleme;
    PRINT 'db_performans_izleme rolü oluşturuldu.';
END;

-- Veri Analiz Rolü
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'db_veri_analiz' AND type = 'R')
BEGIN
    CREATE ROLE db_veri_analiz;
    PRINT 'db_veri_analiz rolü oluşturuldu.';
END;

-- Yedekleme ve Bakım Rolü
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'db_yedekleme_bakim' AND type = 'R')
BEGIN
    CREATE ROLE db_yedekleme_bakim;
    PRINT 'db_yedekleme_bakim rolü oluşturuldu.';
END;
GO

-- 2.5. Admin Rolüne İzinler Verme
-- Amaç: Admin rolünün tüm nesne izinlerini tanımlamak
PRINT CHAR(10) + '2.5. ADMIN ROLÜ İZİNLERİ';

GRANT ALTER, CONTROL, CREATE TABLE, CREATE INDEX, CREATE PROCEDURE, CREATE VIEW 
TO db_veritaban_admin;

GRANT ALTER ANY OBJECT TO db_veritaban_admin;

PRINT 'Admin rolüne izinler verildi.';
GO

-- 2.6. Performans İzleme Rolüne İzinler Verme
-- Amaç: Performans izleme rolünün DMV erişimini sağlamak
PRINT CHAR(10) + '2.6. PERFORMANS İZLEME ROLÜ İZİNLERİ';

GRANT VIEW DATABASE STATE TO db_performans_izleme;
GRANT VIEW SERVER STATE TO db_performans_izleme;
GRANT EXECUTE ON sys.sp_whoisactive TO db_performans_izleme;

PRINT 'Performans izleme rolüne izinler verildi.';
GO

-- 2.7. Veri Analiz Rolüne İzinler Verme
-- Amaç: Veri analizi için gerekli SELECT izinlerini tanımlamak
PRINT CHAR(10) + '2.7. VERİ ANALIZ ROLÜ İZİNLERİ';

GRANT SELECT ON SCHEMA::Sales TO db_veri_analiz;
GRANT SELECT ON SCHEMA::Person TO db_veri_analiz;
GRANT SELECT ON SCHEMA::Production TO db_veri_analiz;

PRINT 'Veri analiz rolüne SELECT izinleri verildi.';
GO

-- 2.8. Yedekleme ve Bakım Rolüne İzinler Verme
-- Amaç: Bakım işleri için gerekli izinleri tanımlamak
PRINT CHAR(10) + '2.8. YEDEKLEME VE BAKIM ROLÜ İZİNLERİ';

GRANT EXECUTE ON sys.sp_updatestats TO db_yedekleme_bakim;
GRANT ALTER ANY OBJECT TO db_yedekleme_bakim;

PRINT 'Yedekleme ve bakım rolüne izinler verildi.';
GO

CREATE OR ALTER PROCEDURE sp_PerformansIzlemesi
AS
BEGIN
    PRINT '========== PERFORMANS İZLEME RAPORU ==========' + CHAR(10);
    
    -- Slow Query'ler
    PRINT 'EN YAVAS 5 SORGU:';
    SELECT TOP 5
        CONVERT(DECIMAL(10,2), qs.[total_elapsed_time] / 1000000) AS [Toplam_Sürü_Saniye],
        qs.[execution_count] AS [Çalıştırma_Sayısı],
        SUBSTRING(st.[text], 1, 50) AS [Sorgu]
    FROM sys.dm_exec_query_stats qs
    CROSS APPLY sys.dm_exec_sql_text(qs.[sql_handle]) st
    ORDER BY qs.[total_elapsed_time] DESC;
    
    -- İndeks İstatistikleri
    PRINT CHAR(10) + 'PARÇALANMIS İNDEKSLER (>30%):';
    SELECT 
        OBJECT_NAME(ips.[object_id]) AS [Tablo],
        i.[name] AS [İndeks],
        CONVERT(DECIMAL(5,2), ips.[avg_fragmentation_in_percent]) AS [Parçalanma_%]
    FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
    INNER JOIN sys.indexes i ON ips.[object_id] = i.[object_id] AND ips.[index_id] = i.[index_id]
    WHERE ips.[avg_fragmentation_in_percent] > 30;
    
    -- Disk Alanı
    PRINT CHAR(10) + 'VERİTABANI DOSYA BOYUTLARI:';
    SELECT 
        mf.[name] AS [Dosya],
        CONVERT(DECIMAL(10,2), mf.[size] * 8 / 1024) AS [Boyut_MB]
    FROM sys.master_files mf
    WHERE database_id = DB_ID();
    
    PRINT CHAR(10) + '========== RAPOR TAMAMLANDI ==========' + CHAR(10);
END;
GO

-- 2.10. İstatistik Bakım Prosedürü
CREATE OR ALTER PROCEDURE sp_IstatistikBakimi
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT 'İstatistikler güncelleniyor...';
    
    EXEC sp_updatestats @resample = 'RESAMPLE';
    
    PRINT 'İstatistikler başarıyla güncellendi.';
    
    SELECT 
        name,
        GETDATE() AS [Son_Güncelleme]
    FROM sys.stats
    WHERE database_id = DB_ID()
    ORDER BY name;
END;
GO

CREATE OR ALTER PROCEDURE sp_IndeksBakimi
    @Defragmentation_Threshold INT = 30
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @TableName NVARCHAR(128);
    DECLARE @IndexName NVARCHAR(128);
    DECLARE @Fragmentation DECIMAL(5,2);
    DECLARE @SQL NVARCHAR(MAX);
    
    PRINT 'İndeks bakımı başlanıyor...';
    
    DECLARE index_cursor CURSOR FOR
    SELECT 
        OBJECT_NAME(ips.[object_id]) AS TableName,
        i.[name] AS IndexName,
        CONVERT(DECIMAL(5,2), ips.[avg_fragmentation_in_percent]) AS Fragmentation
    FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
    INNER JOIN sys.indexes i ON ips.[object_id] = i.[object_id] AND ips.[index_id] = i.[index_id]
    WHERE ips.[avg_fragmentation_in_percent] > 10 
      AND ips.[page_count] > 1000
      AND i.[index_id] > 0;
    
    OPEN index_cursor;
    
    FETCH NEXT FROM index_cursor INTO @TableName, @IndexName, @Fragmentation;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @Fragmentation > @Defragmentation_Threshold
        BEGIN
            SET @SQL = 'ALTER INDEX [' + @IndexName + '] ON [' + @TableName + '] REBUILD;';
            PRINT 'Yeniden oluşturuluyor: ' + @TableName + '.' + @IndexName + ' (' + CONVERT(VARCHAR(5), @Fragmentation) + '%)';
        END
        ELSE
        BEGIN
            SET @SQL = 'ALTER INDEX [' + @IndexName + '] ON [' + @TableName + '] REORGANIZE;';
            PRINT 'Reorganize ediliyor: ' + @TableName + '.' + @IndexName + ' (' + CONVERT(VARCHAR(5), @Fragmentation) + '%)';
        END;
        
        -- EXEC sp_executesql @SQL;
        
        FETCH NEXT FROM index_cursor INTO @TableName, @IndexName, @Fragmentation;
    END;
    
    CLOSE index_cursor;
    DEALLOCATE index_cursor;
    
    PRINT 'İndeks bakımı tamamlandı.';
END;
GO

-- 2.12. Erişim Yönetimi ve İzin Denetimi
-- Amaç: Rol ve izin yapılandırmasını denetlemek
PRINT CHAR(10) + '2.12. OLUŞTURULAN ROLLER VE İZİNLER';

SELECT 
    pr.[name] AS [Rol_Adı],
    pr.[type_desc] AS [Tipi],
    GETDATE() AS [Kontrol_Tarihi]
FROM sys.database_principals pr
WHERE pr.[type] = 'R' AND pr.[is_fixed_role] = 0 AND pr.[name] LIKE 'db_%'
ORDER BY pr.[name];

PRINT CHAR(10) + 'ROL İZİNLERİ:';
SELECT 
    pr.[name] AS [Rol_Adı],
    perm.[permission_name] AS [İzin],
    perm.[state_desc] AS [Durum]
FROM sys.database_principals pr
INNER JOIN sys.database_permissions perm ON pr.[principal_id] = perm.[grantee_principal_id]
WHERE pr.[type] = 'R' AND pr.[name] LIKE 'db_%'
ORDER BY pr.[name], perm.[permission_name];
GO

-- 2.13. Gereksiz İndekslerin Tespit Edilmesi ve Silinmesi
-- Amaç: Hiç kullanılmayan indeksleri tespit edip silme prosedürü oluşturma
-- 2.13. GEREKSİZ İNDEKS ANALİZİ
PRINT CHAR(10) + '2.13. GEREKSİZ (KULLANILMAYAN) İNDEKSLERİN TESPİTİ';
SELECT TOP 15
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    ISNULL(s.user_seeks + s.user_scans + s.user_lookups, 0) AS TotalReads,
    ISNULL(s.user_updates, 0) AS Updates
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats s ON i.object_id = s.object_id AND i.index_id = s.index_id
WHERE i.object_id > 100 AND i.type > 0 AND OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
ORDER BY (s.user_seeks + s.user_scans + s.user_lookups) DESC;
GO

-- 2.13 Prosedürü Çalıştırma - (Not: Procedure tanımı 2.13 sekmesinde)
-- EXEC sp_GereksizIndeksiSil @DeleteUnusedIndexes = 0, @MinimumDaysUnused = 30;
GO

-- 2.14. Query Store ve Sorgu Geçmiş Analizi
-- Amaç: SQL Profiler'a alternatif olarak Query Store ile sorgu geçmişi izleme
PRINT CHAR(10) + '2.14. QUERY STORE - SORGU GEÇMİŞ VE PERFORMANS TAKİBİ';

-- Query Store İstatistikleri (SQL Server 2016+)
IF EXISTS (SELECT 1 FROM sys.database_query_store_options)
BEGIN
    PRINT 'Query Store Durumu:';
    SELECT 
        desired_state_desc AS [Arzu Edilen Durum],
        actual_state_desc AS [Gerçek Durum],
        current_storage_size_mb AS [Şu Anki Depolama (MB)],
        max_storage_size_mb AS [Maksimum Depolama (MB)],
        query_capture_mode_desc AS [Sorgu Yakalama Modu]
    FROM sys.database_query_store_options;
    
    -- Query Store'da En Yavaş Sorgular
    PRINT CHAR(10) + 'Query Store''da En Yavaş Sorgular:';
    SELECT TOP 10
        q.[query_id],
        qt.[query_text_id],
        SUBSTRING(qt.[query_sql_text], 1, 100) AS [Sorgu_İlk_100_Karakter],
        rs.[avg_duration_ms] AS [Ortalama_Süre_MS],
        rs.[execution_count] AS [Çalışma_Sayısı],
        rs.[avg_logical_io_reads] AS [Ortalama_Mantıksal_Okuma]
    FROM sys.query_store_query q
    INNER JOIN sys.query_store_query_text qt ON q.[query_text_id] = qt.[query_text_id]
    INNER JOIN sys.query_store_runtime_stats rs ON q.[query_id] = rs.[query_id]
    ORDER BY rs.[avg_duration_ms] DESC;
END
ELSE
BEGIN
    PRINT 'ℹ️ Query Store bu SQL Server versiyonunda devre dışı veya desteklenmiyor.';
    PRINT 'Query Store, SQL Server 2016 ve sonraki versiyonlarda kullanılabilir.';
END;
GO

-- 2.15. SORGU OPTİMİZASYONU ÖRNEĞİ (BEFORE/AFTER ANALIZI)
-- Amaç: Yavaş bir sorguyu tespit etmek, optimize etmek ve performans iyileştirmesini göstermek
PRINT CHAR(10) + '2.15. SORGU OPTİMİZASYONU ÖRNEĞI - BEFORE/AFTER ANALİZİ';
PRINT CHAR(10) + '===== ADIM 1: KÖTÜ YAZILMIŞ SORGU (BEFORE) =====';

-- Örnek Kötü Sorgu: Nested subquery, SELECT *, JOIN eksik
-- Bu sorgu AdventureWorks2022'de sales verilerini verimsiz şekilde çeker
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

PRINT 'KÖTÜ SORGU ÇALIŞTIRILIYOU (Beklenen: 500-2000ms, Yüksek IO):';
SELECT 
    sod.*,
    (SELECT soh.[OrderDate] FROM Sales.SalesOrderHeader soh WHERE soh.[SalesOrderID] = sod.[SalesOrderID]) AS [OrderDate],
    (SELECT p.[Name] FROM Production.Product p WHERE p.[ProductID] = sod.[ProductID]) AS [ProductName],
    (SELECT TOP 1 so.[Description] FROM Sales.SpecialOfferProduct sop 
     INNER JOIN Sales.SpecialOffer so ON sop.[SpecialOfferID] = so.[SpecialOfferID]
     WHERE sop.[ProductID] = sod.[ProductID]) AS [SpecialOfferName]
FROM Sales.SalesOrderDetail sod
WHERE sod.[OrderQty] > 5
    AND sod.[LineTotal] > (SELECT AVG(LineTotal) FROM Sales.SalesOrderDetail)
ORDER BY sod.[SalesOrderDetailID] DESC;

PRINT CHAR(10) + 'STATISTICS IO VE TIME (Yukarıda Gösterildi)';
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;

GO

-- Eksik Index Oluşturma (Kötü Sorguyu Biraz Hızlandırmak İçin)
PRINT CHAR(10) + '===== ADIM 2: OPTİMİZASYON UYGULANIYOU =====';
PRINT 'Adım 1: OrderQty ve LineTotal üzerine Index oluşturuluyor...';

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE [name] = 'IX_SalesOrderDetail_OrderQty_LineTotal'
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_SalesOrderDetail_OrderQty_LineTotal]
    ON [Sales].[SalesOrderDetail] ([OrderQty], [LineTotal])
    INCLUDE ([ProductID])
    WITH (FILLFACTOR = 90);
    
    PRINT 'Index oluşturuldu: IX_SalesOrderDetail_OrderQty_LineTotal';
END;
GO

-- Adım 2: Sorgu Yeniden Yazma (INNER JOIN ile)
PRINT CHAR(10) + 'Adım 2: Sorgu yeniden yazılıyor (INNER JOIN, spesifik sütunlar)...';
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

PRINT 'OPTIMIZE SORGU ÇALIŞTIRILIYOU (Beklenen: 50-200ms, Düşük IO):';
SELECT 
    sod.[SalesOrderDetailID],
    sod.[SalesOrderID],
    sod.[ProductID],
    sod.[OrderQty],
    sod.[LineTotal],
    soh.[OrderDate],
    p.[Name] AS [ProductName]
FROM Sales.SalesOrderDetail sod
INNER JOIN Sales.SalesOrderHeader soh ON sod.[SalesOrderID] = soh.[SalesOrderID]
INNER JOIN Production.Product p ON sod.[ProductID] = p.[ProductID]
WHERE sod.[OrderQty] > 5
    AND sod.[LineTotal] > (
        SELECT AVG([LineTotal]) 
        FROM Sales.SalesOrderDetail 
        WHERE [OrderQty] > 0
    )
ORDER BY sod.[SalesOrderDetailID] DESC;

PRINT CHAR(10) + 'STATISTICS IO VE TIME (Yukarıda Gösterildi)';
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;

GO



