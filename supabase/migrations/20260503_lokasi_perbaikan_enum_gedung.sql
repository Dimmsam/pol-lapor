BEGIN;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_type
    WHERE typname = 'lokasi_perbaikan_enum'
  ) THEN
    EXECUTE 'ALTER TYPE lokasi_perbaikan_enum RENAME TO lokasi_perbaikan_enum_old';
  END IF;
END $$;

CREATE TYPE lokasi_perbaikan_enum AS ENUM (
  'Gedung A',
  'Gedung B',
  'Gedung C',
  'Gedung D',
  'Gedung E',
  'Gedung F',
  'Gedung G',
  'Gedung H',
  'Gedung Lab Teknik Refrigerasi dan Tata Udara',
  'Gedung Lab Teknik Mesin',
  'Gedung Lab Teknik Kimia',
  'Gedung Lab Teknik Sipil',
  'Hanggar Aero',
  'Student Center',
  'Gedung Serba Guna AN',
  'Gedung Direktorat',
  'Pendopo Tony Soewandito',
  'Gedung P2T'
);

ALTER TABLE formulir_laporan
  ALTER COLUMN lokasi_perbaikan DROP DEFAULT;

ALTER TABLE formulir_laporan
  ALTER COLUMN lokasi_perbaikan TYPE lokasi_perbaikan_enum
  USING (
    CASE
      WHEN lokasi_perbaikan::text IN ('tempat', 'upt_pp', 'luar') THEN NULL
      ELSE lokasi_perbaikan::text::lokasi_perbaikan_enum
    END
  );

DROP TYPE IF EXISTS lokasi_perbaikan_enum_old;

COMMIT;
