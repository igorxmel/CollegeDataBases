-- ---------------------------------------------------------------------------
-- Практическая работа № 6. Каскадные операции и ссылочная целостность
-- База данных Biblioteka, СУБД MySQL 8.0
--
-- Это отдельная база, а не продолжение torgash из пятой работы: методичка
-- прямо требует создать базу «Biblioteka» со своим набором таблиц.
--
-- Порядок создания определён внешними ключами: сначала справочники avtor,
-- zhanr, izdatelstvo и chitatel, затем kniga, последней vydacha.
--
-- Как запускать в Adminer или phpMyAdmin: вкладка SQL, а не Импорт. Импорт
-- спотыкается о DELIMITER, который нужен для тела триггера.
--
-- Движок обязан быть InnoDB: MyISAM внешние ключи разбирает и молча
-- игнорирует, и тогда ни одна каскадная операция работать не будет.
-- ---------------------------------------------------------------------------

SET NAMES utf8mb4;

DROP DATABASE IF EXISTS Biblioteka;
CREATE DATABASE Biblioteka CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE Biblioteka;

-- ----------------------------- Таблица 1. Авторы ---------------------------

CREATE TABLE avtor (
    id_avtor INT AUTO_INCREMENT PRIMARY KEY,
    fio      VARCHAR(100) NOT NULL
) ENGINE = InnoDB;

INSERT INTO avtor (id_avtor, fio) VALUES
(1, 'Л.Н. Толстой'),
(2, 'Н.В. Гоголь'),
(3, 'М.А. Булгаков'),
(4, 'И.А. Бунин'),
(5, 'А.П. Чехов');

-- ----------------------------- Таблица 2. Жанры ----------------------------

CREATE TABLE zhanr (
    id_zhanr INT AUTO_INCREMENT PRIMARY KEY,
    nazvanie VARCHAR(50) NOT NULL
) ENGINE = InnoDB;

INSERT INTO zhanr (id_zhanr, nazvanie) VALUES
(1, 'Роман'),
(2, 'Повесть'),
(3, 'Поэма'),
(4, 'Рассказ'),
(5, 'Пьеса');

-- ----------------------------- Таблица 3. Издательства ---------------------
--
-- Столбец status добавлен по заданию на триггеры. Значение по умолчанию
-- «действующее», второе возможное значение «аннулированное».

CREATE TABLE izdatelstvo (
    id_izd   INT AUTO_INCREMENT PRIMARY KEY,
    nazvanie VARCHAR(100) NOT NULL,
    status   ENUM('действующее', 'аннулированное') NOT NULL DEFAULT 'действующее'
) ENGINE = InnoDB;

INSERT INTO izdatelstvo (id_izd, nazvanie) VALUES
(1, 'АСТ'),
(2, 'Эксмо'),
(3, 'Детская литература');

-- ----------------------------- Таблица 4. Читатели -------------------------

CREATE TABLE chitatel (
    id_chit INT AUTO_INCREMENT PRIMARY KEY,
    fio     VARCHAR(100) NOT NULL,
    dr      DATE NOT NULL
) ENGINE = InnoDB;

INSERT INTO chitatel (id_chit, fio, dr) VALUES
(1, 'Кузнецова Анна Сергеевна', '2004-03-18'),
(2, 'Панфилов Игорь Олегович',  '1998-11-02'),
(3, 'Гришина Марина Павловна',  '2006-07-25');

-- ----------------------------- Таблица 5. Книги ----------------------------
--
-- Каскадные правила из задания:
--   автор удалён        -> книги автора удаляются   (ON DELETE CASCADE)
--   id автора изменён   -> меняется и у книг        (ON UPDATE CASCADE)
--   жанр удалён         -> у книг проставляется NULL (ON DELETE SET NULL)
--   id жанра изменён    -> у книг ничего не меняется (ON UPDATE RESTRICT)
--   издательство удалено-> у книг ничего не меняется (ON DELETE RESTRICT)
--
-- Столбцы id_zhanr и id_izd объявлены NULL: без этого SET NULL объявить
-- нельзя, а id_izd ещё и обнуляется триггером при аннулировании издательства.

CREATE TABLE kniga (
    id_kniga INT AUTO_INCREMENT PRIMARY KEY,
    nazvanie VARCHAR(150) NOT NULL,
    id_avtor INT NOT NULL,
    id_zhanr INT NULL,
    id_izd   INT NULL,

    CONSTRAINT kniga_fk_avtor FOREIGN KEY (id_avtor) REFERENCES avtor (id_avtor)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT kniga_fk_zhanr FOREIGN KEY (id_zhanr) REFERENCES zhanr (id_zhanr)
        ON DELETE SET NULL
        ON UPDATE RESTRICT,

    CONSTRAINT kniga_fk_izd FOREIGN KEY (id_izd) REFERENCES izdatelstvo (id_izd)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT
) ENGINE = InnoDB;

INSERT INTO kniga (id_kniga, nazvanie, id_avtor, id_zhanr, id_izd) VALUES
(1,  'Война и мир',                 1, 1, 1),
(2,  'Анна Каренина',               1, 1, 2),
(3,  'Вий',                         2, 2, 1),
(4,  'Мёртвые души',                2, 3, 3),
(5,  'Мастер и Маргарита',          3, 1, 2),
(6,  'Собачье сердце',              3, 2, 1),
(7,  'Белая гвардия',               3, 1, 2),
(8,  'Гражданин из Сан-Франциско',  4, 4, 1),
(9,  'Жизнь Арсеньева',             4, 1, 2),
(10, 'Палата №6',                   5, 2, 3),
(11, 'Дядя Ваня',                   5, 5, 1),
(12, 'Фальшь',                      5, 5, 2);

-- ----------------------------- Таблица 6. Выдача книг ----------------------
--
-- Каскадные правила из задания:
--   читатель удалён -> его выдачи удаляются      (ON DELETE CASCADE)
--   книга удалена   -> в выдаче проставляется NULL (ON DELETE SET NULL)
--
-- Столбец data_sdachi допускает NULL: книга может быть ещё на руках.

CREATE TABLE vydacha (
    id_vyd      INT AUTO_INCREMENT PRIMARY KEY,
    data_vydachi DATE NOT NULL,
    id_kniga    INT NULL,
    data_sdachi DATE NULL,
    id_chit     INT NOT NULL,

    CONSTRAINT vydacha_fk_kniga FOREIGN KEY (id_kniga) REFERENCES kniga (id_kniga)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT vydacha_fk_chit FOREIGN KEY (id_chit) REFERENCES chitatel (id_chit)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE = InnoDB;

INSERT INTO vydacha (id_vyd, data_vydachi, id_kniga, data_sdachi, id_chit) VALUES
(1,  '2026-01-12', 1,  '2026-01-26', 1),
(2,  '2026-01-15', 5,  '2026-02-01', 2),
(3,  '2026-01-20', 3,  '2026-02-03', 3),
(4,  '2026-02-02', 2,  '2026-02-16', 1),
(5,  '2026-02-05', 11, '2026-02-19', 2),
(6,  '2026-02-10', 4,  '2026-02-24', 3),
(7,  '2026-02-18', 6,  '2026-03-04', 1),
(8,  '2026-02-25', 9,  '2026-03-11', 2),
(9,  '2026-03-01', 8,  '2026-03-15', 3),
(10, '2026-03-07', 10, '2026-03-21', 1),
(11, '2026-03-14', 7,  '2026-03-28', 2),
(12, '2026-03-20', 12, '2026-04-03', 3),
(13, '2026-04-01', 1,  NULL,         2),
(14, '2026-04-06', 5,  NULL,         3),
(15, '2026-04-10', 2,  NULL,         1);

-- ----------------------------- Триггер -------------------------------------
--
-- При смене статуса издательства с «действующее» на «аннулированное» у его
-- книг во внешнем ключе выставляется NULL.
--
-- Триггер AFTER UPDATE, а не BEFORE: книги должны отвязаться от уже
-- изменённой строки, и на момент BEFORE новый статус в таблице ещё не
-- записан. Условие сравнивает старое и новое значение, иначе он срабатывал бы
-- на любом обновлении строки, в том числе на переименовании издательства.

DELIMITER $$

CREATE TRIGGER izdatelstvo_after_update
AFTER UPDATE ON izdatelstvo
FOR EACH ROW
BEGIN
    IF OLD.status = 'действующее' AND NEW.status = 'аннулированное' THEN
        UPDATE kniga
        SET id_izd = NULL
        WHERE id_izd = NEW.id_izd;
    END IF;
END$$

DELIMITER ;
