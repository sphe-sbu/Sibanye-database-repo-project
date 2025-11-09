CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '====================================================';
        PRINT 'Loading Silver Layer';
        PRINT '====================================================';

        PRINT '----------------------------------------------------';
        PRINT 'Loading Sibanye Table'
        PRINT '----------------------------------------------------';

		        -- Loading silver.sibanye_doc
        SET @start_time = GETDATE();

        PRINT '>> Truncating table silver.sibanye_doc';
        TRUNCATE TABLE silver.sibanye_doc;

        PRINT '>> Inserting data into silver.sibanye_doc';
        INSERT INTO silver.sibanye_doc(
        NO,REF,
        COMPANY_NAME, ID_NUMBER, NATURE_OF_BUSINESS,
        AREA, MUNICIPALITY, VENDOR_NUMBER, ATTENDEE_INITIALS, ATTENDEE_SURNAME,
        BYO, BWO, BDO, BEE_LEVEL, ED, SD,
        MODULE_1, MODULE_2, MODULE_3, MODULE_4, MODULE_5, MODULE_6,
        EMAIL, CONTACT_NUMBER, CLIENT, HUB,
        PROGRAM_TYPE,
        PROGRAM_NM
        )

        SELECT 
            NO,
            REF,
            UPPER(TRIM(COMPAN_NAME)) AS COMPANY_NAME,

            CASE  WHEN LEN(ID_NUMBER) = 13 AND ID_NUMBER LIKE '%[0-9]%'
                     THEN ID_NUMBER
                  ELSE NULL
            END AS ID_NUMBER,

            UPPER(TRIM(NATURE_OF_BUSINESS)) AS NATURE_OF_BUSINUSS,
            UPPER(TRIM(AREA)) AS AREA,
            TRIM(MUNICIPALITY) AS MUNICIPALITY,
            TRIM(VENDOR_NUMBER) AS VENDOR_NUMBER,
            UPPER(TRIM(ATTENDEE_INITIALS)) AS ATTENDEE_INITIALS,
            UPPER(TRIM(ATTENDEE_SURNAME))AS ATENDEE_SURNAME,
            BYO, BWO, BDO, BEE_LEVEL, ED, SD,
            MODULE_1, MODULE_2, MODULE_3, MODULE_4, MODULE_5, MODULE_6,

            CASE 
                WHEN EMAIL LIKE 'dmnmouthriverprojects@gmailcom'
                THEN REPLACE(TRIM(EMAIL), '@gmailcom', '@gmail.com')
                ELSE EMAIL
            END AS EMAIL,

            CASE WHEN LEN(CONTACT_NUMBER) = 10 AND CONTACT_NUMBER LIKE '%[0-9]%'
                     THEN CONTACT_NUMBER
                 ELSE NULL
            END AS CONTACT_NUMBER,

            UPPER(TRIM(CLIENT)) AS CLIENT,
            UPPER(TRIM(HUB)) AS HUB,
            UPPER(TRIM(PROGRAM_TYPE)) AS PROGRAM_TYPE,
            UPPER(TRIM(PROGRAM_NM)) AS PROGRAM_NM
        FROM (
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY ID_NUMBER, PROGRAM_NM ORDER BY NO) AS FLAG
            FROM bronze.sibanye_doc
        )t
        WHERE FLAG = 1;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'seconds';
        PRINT '---------------------------------'

        SET @batch_end_time = GETDATE();

        PRINT '=================================='
        PRINT 'Loading Silver Layer';
        PRINT '  - Total loading Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + 'seconds';
        PRINT '=================================='
    END TRY

    BEGIN CATCH
        PRINT '==================================='
        PRINT 'Error Occured During Loading Silver Layer'
        PRINT 'Error Massage' + ERROR_MESSAGE();
        PRINT 'Error Massage' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Massage' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==================================='
    END CATCH
END
