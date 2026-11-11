-- Pre-check for LOAD DATA INFILE / INTO OUTFILE on a machine without Docker
-- (for example Open Server Panel + phpMyAdmin).
-- Run it on the SQL tab. Change only the path in the first line.

SET @path = 'C:/temp/postavki.csv';

-- 1. Server version (MySQL or MariaDB).
SELECT VERSION() AS server_version;

-- 2. Folder the server allows for file import and export.
--    A path means: put the files only there.
--    Empty means: any folder works.
--    NULL means: LOAD DATA INFILE and INTO OUTFILE are disabled.
SELECT @@secure_file_priv AS allowed_folder;

-- 3. Can this user work with files at all (the FILE privilege).
--    Look for FILE or ALL PRIVILEGES in the result.
SHOW GRANTS;

-- 4. Can the server read the file at @path.
--    file_size is NULL if the path is wrong, the folder is not allowed,
--    or the server has no access to it.
SELECT LENGTH(LOAD_FILE(@path)) AS file_size;

-- 5. Line endings of the file: crlf = 1 means '\r\n', 0 means '\n'.
--    It decides what goes into LINES TERMINATED BY.
SELECT LOCATE(CHAR(13), LOAD_FILE(@path)) > 0 AS crlf;
