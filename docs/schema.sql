
-- =====================================================
-- Distributed Face Recognition Attendance System
-- Day 2: Relational Database Schema
-- Database: attendance_db
-- MySQL: 8.0+
-- Storage Engine: InnoDB
-- =====================================================

USE attendance_db;

-- =====================================================
-- 1. USERS TABLE
-- Stores system users and their authentication details
-- =====================================================

CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    department VARCHAR(100),
    role VARCHAR(30) NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_users_email UNIQUE (email)

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;


-- =====================================================
-- 2. FACE_EMBEDDINGS TABLE
-- Stores 512-dimensional float32 face embeddings
-- 512 * 4 bytes = 2048 bytes
-- One embedding per user
-- =====================================================

CREATE TABLE face_embeddings (
    user_id BIGINT UNSIGNED PRIMARY KEY,

    embedding_blob VARBINARY(2048) NOT NULL,
    model_version VARCHAR(50) NOT NULL,

    updated_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT chk_embedding_size
        CHECK (OCTET_LENGTH(embedding_blob) = 2048),

    CONSTRAINT fk_face_embeddings_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;


-- =====================================================
-- 3. ATTENDANCE_SESSIONS TABLE
-- Represents individual attendance sessions
-- =====================================================

CREATE TABLE attendance_sessions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    title VARCHAR(150) NOT NULL,
    start_time DATETIME NOT NULL,
    late_after_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,

    status VARCHAR(30) NOT NULL,

    CONSTRAINT chk_session_time
        CHECK (
            start_time <= late_after_time
            AND late_after_time <= end_time
        ),

    INDEX idx_session_status_start (status, start_time)

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;


-- =====================================================
-- 4. ATTENDANCE_LOGS TABLE
-- Stores individual attendance check-in records
-- =====================================================

CREATE TABLE attendance_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    user_id BIGINT UNSIGNED NOT NULL,
    session_id BIGINT UNSIGNED NOT NULL,

    checked_in_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    status VARCHAR(20) NOT NULL,

    confidence_score DECIMAL(5,4) NOT NULL,

    -- Prevent duplicate check-ins for the same session
    CONSTRAINT uq_user_session
        UNIQUE KEY (user_id, session_id),

    -- User relationship
    CONSTRAINT fk_attendance_logs_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- Session relationship
    CONSTRAINT fk_attendance_logs_session
        FOREIGN KEY (session_id)
        REFERENCES attendance_sessions(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- Confidence must be between 0 and 1
    CONSTRAINT chk_confidence_score
        CHECK (confidence_score BETWEEN 0.0000 AND 1.0000),

    -- Dashboard pagination and session-wise attendance lookup
    INDEX idx_session_checked_in (session_id, checked_in_at)

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;


-- =====================================================
-- END OF SCHEMA
-- =====================================================
