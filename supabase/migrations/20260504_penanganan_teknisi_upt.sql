-- supabase/migrations/20260504_penanganan_teknisi_upt.sql
-- Migrasi untuk mendukung fitur Teknisi UPT-PP
-- Disesuaikan dengan skema DB aktual (status_penanganan_enum, foto_progres_url ARRAY)
-- Jalankan di Supabase SQL Editor

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────
-- CATATAN SKEMA AKTUAL
-- Tabel penanganan sudah memiliki kolom-kolom berikut (tidak perlu ALTER):
--   penanganan_id     uuid            PK
--   surat_kerja_id    uuid            FK → surat_kerja
--   formulir_id       uuid            FK → formulir_laporan
--   teknisi_id        uuid            FK → pengguna
--   status_penanganan status_penanganan_enum  DEFAULT 'mulai_dikerjakan'
--     (nilai valid: mulai_dikerjakan | sedang_dikerjakan | selesai)
--   catatan_progres   text
--   deskripsi_hasil   text
--   foto_progres_url  text[]          (ARRAY — append setiap update progress)
--   foto_hasil_url    text
--   tanggal_mulai     timestamptz
--   tanggal_selesai   timestamptz
--   updated_at        timestamptz     DEFAULT now()
-- ─────────────────────────────────────────────────────────────────────────────

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Index untuk query umum
-- ─────────────────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_surat_kerja_teknisi_id
  ON surat_kerja (teknisi_id);

CREATE INDEX IF NOT EXISTS idx_surat_kerja_jenis_pelaksana
  ON surat_kerja (jenis_pelaksana);

CREATE INDEX IF NOT EXISTS idx_penanganan_surat_kerja_id
  ON penanganan (surat_kerja_id);

CREATE INDEX IF NOT EXISTS idx_penanganan_formulir_id
  ON penanganan (formulir_id);

CREATE INDEX IF NOT EXISTS idx_penanganan_teknisi_id
  ON penanganan (teknisi_id);

CREATE INDEX IF NOT EXISTS idx_penanganan_status
  ON penanganan (status_penanganan);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Row Level Security (RLS) — tabel penanganan
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE penanganan ENABLE ROW LEVEL SECURITY;

-- SELECT: teknisi lihat miliknya; admin/ketua lihat semua
DROP POLICY IF EXISTS "teknisi_select_own_penanganan" ON penanganan;
CREATE POLICY "teknisi_select_own_penanganan"
  ON penanganan FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM pengguna
      WHERE pengguna.auth_id = auth.uid()
        AND pengguna.user_id = penanganan.teknisi_id
    )
    OR EXISTS (
      SELECT 1 FROM pengguna
      WHERE pengguna.auth_id = auth.uid()
        AND pengguna.role IN ('admin_upt_pp', 'ketua_upt_pp')
    )
  );

-- INSERT: teknisi hanya bisa insert untuk surat kerja miliknya
DROP POLICY IF EXISTS "teknisi_insert_penanganan" ON penanganan;
CREATE POLICY "teknisi_insert_penanganan"
  ON penanganan FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM surat_kerja sk
      JOIN pengguna p ON p.auth_id = auth.uid()
      WHERE sk.surat_kerja_id = penanganan.surat_kerja_id
        AND sk.teknisi_id = p.user_id
    )
  );

-- UPDATE: teknisi hanya bisa update penanganannya sendiri
DROP POLICY IF EXISTS "teknisi_update_own_penanganan" ON penanganan;
CREATE POLICY "teknisi_update_own_penanganan"
  ON penanganan FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM pengguna
      WHERE pengguna.auth_id = auth.uid()
        AND pengguna.user_id = penanganan.teknisi_id
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Row Level Security (RLS) — tabel surat_kerja
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE surat_kerja ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "teknisi_select_own_surat_kerja" ON surat_kerja;
CREATE POLICY "teknisi_select_own_surat_kerja"
  ON surat_kerja FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM pengguna
      WHERE pengguna.auth_id = auth.uid()
        AND (
          pengguna.user_id = surat_kerja.teknisi_id
          OR pengguna.role IN ('admin_upt_pp', 'ketua_upt_pp')
        )
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Row Level Security (RLS) — tabel formulir_laporan
--    Teknisi perlu UPDATE status formulir saat mulai & selesai pengerjaan.
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE formulir_laporan ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "authenticated_select_formulir" ON formulir_laporan;
CREATE POLICY "authenticated_select_formulir"
  ON formulir_laporan FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "teknisi_update_formulir_via_surat_kerja" ON formulir_laporan;
CREATE POLICY "teknisi_update_formulir_via_surat_kerja"
  ON formulir_laporan FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM surat_kerja sk
      JOIN pengguna p ON p.auth_id = auth.uid()
      WHERE sk.formulir_id = formulir_laporan.formulir_id
        AND sk.teknisi_id = p.user_id
    )
    OR EXISTS (
      SELECT 1 FROM pengguna
      WHERE pengguna.auth_id = auth.uid()
        AND pengguna.role IN ('admin_upt_pp', 'ketua_upt_pp')
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Row Level Security (RLS) — tabel tracking
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE tracking ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "authenticated_select_tracking" ON tracking;
CREATE POLICY "authenticated_select_tracking"
  ON tracking FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "authenticated_insert_tracking" ON tracking;
CREATE POLICY "authenticated_insert_tracking"
  ON tracking FOR INSERT
  TO authenticated
  WITH CHECK (
    aktor_id = (
      SELECT user_id FROM pengguna WHERE auth_id = auth.uid()
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. Storage bucket 'bukti_laporan'
--    Subfolder: foto_kerusakan/ | foto_progres/ | foto_hasil/
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public)
  VALUES ('bukti_laporan', 'bukti_laporan', true)
  ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "authenticated_upload_bukti" ON storage.objects;
CREATE POLICY "authenticated_upload_bukti"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'bukti_laporan');

DROP POLICY IF EXISTS "authenticated_update_bukti" ON storage.objects;
CREATE POLICY "authenticated_update_bukti"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'bukti_laporan');

DROP POLICY IF EXISTS "public_read_bukti" ON storage.objects;
CREATE POLICY "public_read_bukti"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'bukti_laporan');

COMMIT;