-- =============================================================================
-- C006: reference seed — the catalog data the application needs to function
--       (Phase 9.2, decision D32: databases are rebuilt from migrations, no data is copied)
--
-- * Every row has a FIXED, human-readable code so partner seeds, unit tests and the
--   devstack can refer to rows by literal:  c0deTTTT-0000-4000-8000-<old integer id, 12 digits>
--   TTTT = table number (0001 Sex, 0002 DocumentType, 0003 Specialty, 0004 PharmaceuticalForm,
--   0005 AdministrationRoute, 0006 Frequency, 0007 Allergy, 0008 AllergySeverity,
--   0009 Medication, 0010 Insurance, 0011 MedicationClass).
-- * The integer ids are kept equal to the legacy partner ids only so the old demo data can be
--   mapped; nothing outside the catalog may depend on them.
-- * Specialty prices are NOT catalog data (they live in the partner's PartnerSpecialty).
-- * The medication list and the allergy / interaction rules are SYNTHETIC reference content
--   for development; the production clinical content is curated through rxlink-platform and
--   needs clinical review before real use.
-- * Seed runs as the migration owner with no app.user_code, so the audit triggers write rows
--   with a NULL actor (same as the earlier seed-from-partner load).
-- =============================================================================

INSERT INTO "Sex" ("SexId", "SexCode", "Name") OVERRIDING SYSTEM VALUE VALUES
    (1, 'c0de0001-0000-4000-8000-000000000001', 'Masculino'),
    (2, 'c0de0001-0000-4000-8000-000000000002', 'Femenino');
SELECT setval(pg_get_serial_sequence('"Sex"', 'SexId'), (SELECT MAX("SexId") FROM "Sex"));

INSERT INTO "DocumentType" ("DocumentTypeId", "DocumentTypeCode", "Name") OVERRIDING SYSTEM VALUE VALUES
    (1, 'c0de0002-0000-4000-8000-000000000001', 'DNI'),
    (2, 'c0de0002-0000-4000-8000-000000000002', 'Pasaporte'),
    (3, 'c0de0002-0000-4000-8000-000000000003', 'Carné de extranjería');
SELECT setval(pg_get_serial_sequence('"DocumentType"', 'DocumentTypeId'), (SELECT MAX("DocumentTypeId") FROM "DocumentType"));

INSERT INTO "Specialty" ("SpecialtyId", "SpecialtyCode", "Name") OVERRIDING SYSTEM VALUE VALUES
    (1, 'c0de0003-0000-4000-8000-000000000001', 'Medicina General'),
    (2, 'c0de0003-0000-4000-8000-000000000002', 'Cardiología'),
    (3, 'c0de0003-0000-4000-8000-000000000003', 'Neurología'),
    (4, 'c0de0003-0000-4000-8000-000000000004', 'Pediatría'),
    (5, 'c0de0003-0000-4000-8000-000000000005', 'Ginecología y Obstetricia'),
    (6, 'c0de0003-0000-4000-8000-000000000006', 'Traumatología y Ortopedia'),
    (7, 'c0de0003-0000-4000-8000-000000000007', 'Dermatología'),
    (8, 'c0de0003-0000-4000-8000-000000000008', 'Oftalmología'),
    (9, 'c0de0003-0000-4000-8000-000000000009', 'Otorrinolaringología'),
    (10, 'c0de0003-0000-4000-8000-000000000010', 'Gastroenterología'),
    (11, 'c0de0003-0000-4000-8000-000000000011', 'Neumología'),
    (12, 'c0de0003-0000-4000-8000-000000000012', 'Endocrinología'),
    (13, 'c0de0003-0000-4000-8000-000000000013', 'Reumatología'),
    (14, 'c0de0003-0000-4000-8000-000000000014', 'Nefrología'),
    (15, 'c0de0003-0000-4000-8000-000000000015', 'Urología'),
    (16, 'c0de0003-0000-4000-8000-000000000016', 'Oncología'),
    (17, 'c0de0003-0000-4000-8000-000000000017', 'Hematología'),
    (18, 'c0de0003-0000-4000-8000-000000000018', 'Infectología'),
    (19, 'c0de0003-0000-4000-8000-000000000019', 'Psiquiatría'),
    (20, 'c0de0003-0000-4000-8000-000000000020', 'Medicina Interna'),
    (21, 'c0de0003-0000-4000-8000-000000000021', 'Cirugía General'),
    (22, 'c0de0003-0000-4000-8000-000000000022', 'Cirugía Cardiovascular'),
    (23, 'c0de0003-0000-4000-8000-000000000023', 'Cirugía Plástica y Reconstructiva'),
    (24, 'c0de0003-0000-4000-8000-000000000024', 'Anestesiología'),
    (25, 'c0de0003-0000-4000-8000-000000000025', 'Radiología e Imagen'),
    (26, 'c0de0003-0000-4000-8000-000000000026', 'Medicina de Emergencias'),
    (27, 'c0de0003-0000-4000-8000-000000000027', 'Geriatría'),
    (28, 'c0de0003-0000-4000-8000-000000000028', 'Medicina Física y Rehabilitación'),
    (29, 'c0de0003-0000-4000-8000-000000000029', 'Nutrición Clínica'),
    (30, 'c0de0003-0000-4000-8000-000000000030', 'Odontología General');
SELECT setval(pg_get_serial_sequence('"Specialty"', 'SpecialtyId'), (SELECT MAX("SpecialtyId") FROM "Specialty"));

INSERT INTO "PharmaceuticalForm" ("PharmaceuticalFormId", "PharmaceuticalFormCode", "Name") OVERRIDING SYSTEM VALUE VALUES
    (1, 'c0de0004-0000-4000-8000-000000000001', 'Tableta'),
    (2, 'c0de0004-0000-4000-8000-000000000002', 'Cápsula'),
    (3, 'c0de0004-0000-4000-8000-000000000003', 'Jarabe'),
    (4, 'c0de0004-0000-4000-8000-000000000004', 'Solución inyectable'),
    (5, 'c0de0004-0000-4000-8000-000000000005', 'Crema'),
    (6, 'c0de0004-0000-4000-8000-000000000006', 'Ungüento'),
    (7, 'c0de0004-0000-4000-8000-000000000007', 'Gotas'),
    (8, 'c0de0004-0000-4000-8000-000000000008', 'Parche'),
    (9, 'c0de0004-0000-4000-8000-000000000009', 'Supositorio'),
    (10, 'c0de0004-0000-4000-8000-000000000010', 'Polvo');
SELECT setval(pg_get_serial_sequence('"PharmaceuticalForm"', 'PharmaceuticalFormId'), (SELECT MAX("PharmaceuticalFormId") FROM "PharmaceuticalForm"));

INSERT INTO "AdministrationRoute" ("AdministrationRouteId", "AdministrationRouteCode", "Name") OVERRIDING SYSTEM VALUE VALUES
    (1, 'c0de0005-0000-4000-8000-000000000001', 'Oral'),
    (2, 'c0de0005-0000-4000-8000-000000000002', 'Intravenosa'),
    (3, 'c0de0005-0000-4000-8000-000000000003', 'Intramuscular'),
    (4, 'c0de0005-0000-4000-8000-000000000004', 'Subcutánea'),
    (5, 'c0de0005-0000-4000-8000-000000000005', 'Tópica'),
    (6, 'c0de0005-0000-4000-8000-000000000006', 'Inhalatoria'),
    (7, 'c0de0005-0000-4000-8000-000000000007', 'Sublingual'),
    (8, 'c0de0005-0000-4000-8000-000000000008', 'Rectal');
SELECT setval(pg_get_serial_sequence('"AdministrationRoute"', 'AdministrationRouteId'), (SELECT MAX("AdministrationRouteId") FROM "AdministrationRoute"));

INSERT INTO "Frequency" ("FrequencyId", "FrequencyCode", "Description", "IntervalHours") OVERRIDING SYSTEM VALUE VALUES
    (1, 'c0de0006-0000-4000-8000-000000000001', 'Una vez al día', 24),
    (2, 'c0de0006-0000-4000-8000-000000000002', 'Dos veces al día', 12),
    (3, 'c0de0006-0000-4000-8000-000000000003', 'Cada 8 horas', 8),
    (4, 'c0de0006-0000-4000-8000-000000000004', 'Cada 6 horas', 6),
    (5, 'c0de0006-0000-4000-8000-000000000005', 'Cada 4 horas', 4),
    (6, 'c0de0006-0000-4000-8000-000000000006', 'Cada 12 horas', 12),
    (7, 'c0de0006-0000-4000-8000-000000000007', 'Una vez a la semana', 168),
    (8, 'c0de0006-0000-4000-8000-000000000008', 'Días alternos', 48);
SELECT setval(pg_get_serial_sequence('"Frequency"', 'FrequencyId'), (SELECT MAX("FrequencyId") FROM "Frequency"));

INSERT INTO "AllergySeverity" ("SeverityId", "SeverityCode", "Name", "SortOrder") OVERRIDING SYSTEM VALUE VALUES
    (1, 'c0de0008-0000-4000-8000-000000000001', 'Leve', 1),
    (2, 'c0de0008-0000-4000-8000-000000000002', 'Moderada', 2),
    (3, 'c0de0008-0000-4000-8000-000000000003', 'Grave', 3),
    (4, 'c0de0008-0000-4000-8000-000000000004', 'Anafiláctica', 4);
SELECT setval(pg_get_serial_sequence('"AllergySeverity"', 'SeverityId'), (SELECT MAX("SeverityId") FROM "AllergySeverity"));

INSERT INTO "Allergy" ("AllergyId", "AllergyCode", "Name", "Description") OVERRIDING SYSTEM VALUE VALUES
    (1, 'c0de0007-0000-4000-8000-000000000001', 'Penicilina', 'Reacción alérgica a antibióticos betalactámicos del grupo de las penicilinas.'),
    (2, 'c0de0007-0000-4000-8000-000000000002', 'Amoxicilina', 'Hipersensibilidad a la amoxicilina y aminopenicilinas.'),
    (3, 'c0de0007-0000-4000-8000-000000000003', 'Sulfonamidas', 'Reacción a antibióticos derivados de las sulfas.'),
    (4, 'c0de0007-0000-4000-8000-000000000004', 'Cefalosporinas', 'Hipersensibilidad a antibióticos del grupo de las cefalosporinas.'),
    (5, 'c0de0007-0000-4000-8000-000000000005', 'Látex', 'Reacción alérgica a productos de látex natural.'),
    (6, 'c0de0007-0000-4000-8000-000000000006', 'Maní', 'Alergia a proteínas del maní o cacahuate.'),
    (7, 'c0de0007-0000-4000-8000-000000000007', 'Mariscos', 'Alergia a crustáceos y moluscos.'),
    (8, 'c0de0007-0000-4000-8000-000000000008', 'Polen', 'Rinitis o asma por sensibilización a polen de gramíneas y árboles.'),
    (9, 'c0de0007-0000-4000-8000-000000000009', 'Ácaros del polvo', 'Sensibilización a ácaros del polvo doméstico.'),
    (10, 'c0de0007-0000-4000-8000-000000000010', 'Leche de vaca', 'Alergia a las proteínas de la leche de vaca.'),
    (11, 'c0de0007-0000-4000-8000-000000000011', 'Picadura de abeja o avispa', 'Reacción local o sistémica al veneno de himenópteros.'),
    (12, 'c0de0007-0000-4000-8000-000000000012', 'Aspirina', 'Reacción adversa al ácido acetilsalicílico (AINE).'),
    (13, 'c0de0007-0000-4000-8000-000000000013', 'Ibuprofeno', 'Hipersensibilidad a antiinflamatorios no esteroideos.'),
    (14, 'c0de0007-0000-4000-8000-000000000014', 'Codeína', 'Reacción a opioides débiles derivados de la morfina.'),
    (15, 'c0de0007-0000-4000-8000-000000000015', 'Morfina', 'Hipersensibilidad a analgésicos opioides mayores.'),
    (16, 'c0de0007-0000-4000-8000-000000000016', 'Contraste yodado', 'Reacción al medio de contraste radiológico intravenoso.'),
    (17, 'c0de0007-0000-4000-8000-000000000017', 'Huevo', 'Alergia a proteínas presentes en la clara o yema de huevo.'),
    (18, 'c0de0007-0000-4000-8000-000000000018', 'Trigo / Gluten', 'Intolerancia o reacción inmunológica al gluten del trigo.'),
    (19, 'c0de0007-0000-4000-8000-000000000019', 'Soja', 'Reacción alérgica a proteínas de la soja.'),
    (20, 'c0de0007-0000-4000-8000-000000000020', 'Nueces de árbol', 'Hipersensibilidad a almendras, avellanas, nueces o pistachos.'),
    (21, 'c0de0007-0000-4000-8000-000000000021', 'Lidocaína', 'Reacción a anestésico local tipo amida.'),
    (22, 'c0de0007-0000-4000-8000-000000000022', 'Enalapril', 'Hipersensibilidad a inhibidores de la enzima convertidora de angiotensina.'),
    (23, 'c0de0007-0000-4000-8000-000000000023', 'Atorvastatina', 'Reacción adversa a estatinas empleadas en dislipidemia.'),
    (24, 'c0de0007-0000-4000-8000-000000000024', 'Metformina', 'Intolerancia o reacción adversa a biguanidas antidiabéticas.'),
    (25, 'c0de0007-0000-4000-8000-000000000025', 'Caspa de animales', 'Sensibilización a alérgenos de pelo o piel de gatos y perros.'),
    (26, 'c0de0007-0000-4000-8000-000000000026', 'Ácaros de almacenamiento', 'Sensibilidad a ácaros presentes en granos y harinas almacenados.');
SELECT setval(pg_get_serial_sequence('"Allergy"', 'AllergyId'), (SELECT MAX("AllergyId") FROM "Allergy"));

INSERT INTO "Insurance" ("InsuranceId", "InsuranceCode", "Name", "DefaultCoveragePercentage") OVERRIDING SYSTEM VALUE VALUES
    (1, 'c0de0010-0000-4000-8000-000000000001', 'EsSalud', 100.0),
    (2, 'c0de0010-0000-4000-8000-000000000002', 'SIS', 100.0),
    (3, 'c0de0010-0000-4000-8000-000000000003', 'Pacífico Seguros', 80.0),
    (4, 'c0de0010-0000-4000-8000-000000000004', 'Rimac Seguros', 80.0),
    (5, 'c0de0010-0000-4000-8000-000000000005', 'La Positiva', 70.0),
    (6, 'c0de0010-0000-4000-8000-000000000006', 'Mapfre Perú', 70.0),
    (7, 'c0de0010-0000-4000-8000-000000000007', 'Sanitas Perú', 75.0);
SELECT setval(pg_get_serial_sequence('"Insurance"', 'InsuranceId'), (SELECT MAX("InsuranceId") FROM "Insurance"));

INSERT INTO "Medication" ("MedicationId", "MedicationCode", "PharmaceuticalFormId", "AdministrationRouteId", "GenericName", "CommercialName", "Concentration") OVERRIDING SYSTEM VALUE VALUES
    (1, 'c0de0009-0000-4000-8000-000000000001', 2, 1, 'Amoxicilina', 'Amoxil', '500 mg'),
    (2, 'c0de0009-0000-4000-8000-000000000002', 3, 1, 'Amoxicilina', 'Amoxil', '250 mg/5 mL'),
    (3, 'c0de0009-0000-4000-8000-000000000003', 1, 1, 'Amoxicilina + ácido clavulánico', 'Augmentin', '875 mg/125 mg'),
    (4, 'c0de0009-0000-4000-8000-000000000004', 1, 1, 'Azitromicina', 'Zitromax', '500 mg'),
    (5, 'c0de0009-0000-4000-8000-000000000005', 1, 1, 'Ciprofloxacino', 'Ciproxina', '500 mg'),
    (6, 'c0de0009-0000-4000-8000-000000000006', 2, 1, 'Cefalexina', 'Keflex', '500 mg'),
    (7, 'c0de0009-0000-4000-8000-000000000007', 4, 3, 'Ceftriaxona', 'Rocephin', '1 g'),
    (8, 'c0de0009-0000-4000-8000-000000000008', 2, 1, 'Clindamicina', 'Dalacin', '300 mg'),
    (9, 'c0de0009-0000-4000-8000-000000000009', 2, 1, 'Doxiciclina', 'Vibramicina', '100 mg'),
    (10, 'c0de0009-0000-4000-8000-000000000010', 1, 1, 'Metronidazol', 'Flagyl', '500 mg'),
    (11, 'c0de0009-0000-4000-8000-000000000011', 1, 1, 'Cotrimoxazol', 'Bactrim', '800 mg/160 mg'),
    (12, 'c0de0009-0000-4000-8000-000000000012', 2, 1, 'Nitrofurantoína', 'Macrodantina', '100 mg'),
    (13, 'c0de0009-0000-4000-8000-000000000013', 2, 1, 'Fluconazol', 'Diflucan', '150 mg'),
    (14, 'c0de0009-0000-4000-8000-000000000014', 1, 1, 'Aciclovir', 'Zovirax', '400 mg'),
    (15, 'c0de0009-0000-4000-8000-000000000015', 2, 1, 'Omeprazol', 'Losec', '20 mg'),
    (16, 'c0de0009-0000-4000-8000-000000000016', 1, 1, 'Ivermectina', 'Ivexterm', '6 mg'),
    (17, 'c0de0009-0000-4000-8000-000000000017', 1, 1, 'Losartán', 'Cozaar', '50 mg'),
    (18, 'c0de0009-0000-4000-8000-000000000018', 1, 1, 'Albendazol', 'Zentel', '400 mg'),
    (19, 'c0de0009-0000-4000-8000-000000000019', 1, 1, 'Ibuprofeno', 'Advil', '400 mg'),
    (20, 'c0de0009-0000-4000-8000-000000000020', 1, 1, 'Naproxeno', 'Flanax', '550 mg'),
    (21, 'c0de0009-0000-4000-8000-000000000021', 1, 1, 'Diclofenaco', 'Voltaren', '50 mg'),
    (22, 'c0de0009-0000-4000-8000-000000000022', 4, 3, 'Diclofenaco', 'Voltaren', '75 mg/3 mL'),
    (23, 'c0de0009-0000-4000-8000-000000000023', 1, 1, 'Ketorolaco', 'Toradol', '10 mg'),
    (24, 'c0de0009-0000-4000-8000-000000000024', 1, 1, 'Metamizol', 'Novalgina', '500 mg'),
    (25, 'c0de0009-0000-4000-8000-000000000025', 2, 1, 'Tramadol', 'Tramal', '50 mg'),
    (26, 'c0de0009-0000-4000-8000-000000000026', 4, 4, 'Morfina', NULL, '10 mg/mL'),
    (27, 'c0de0009-0000-4000-8000-000000000027', 1, 1, 'Ácido acetilsalicílico', 'Aspirina', '100 mg'),
    (28, 'c0de0009-0000-4000-8000-000000000028', 1, 1, 'Clopidogrel', 'Plavix', '75 mg'),
    (29, 'c0de0009-0000-4000-8000-000000000029', 1, 1, 'Warfarina', 'Coumadin', '5 mg'),
    (30, 'c0de0009-0000-4000-8000-000000000030', 4, 4, 'Enoxaparina', 'Clexane', '40 mg/0.4 mL'),
    (31, 'c0de0009-0000-4000-8000-000000000031', 1, 1, 'Carvedilol', 'Dilatrend', '25 mg'),
    (32, 'c0de0009-0000-4000-8000-000000000032', 1, 1, 'Bisoprolol', 'Concor', '5 mg'),
    (33, 'c0de0009-0000-4000-8000-000000000033', 1, 1, 'Metformina', 'Glucophage', '850 mg'),
    (34, 'c0de0009-0000-4000-8000-000000000034', 1, 1, 'Propranolol', 'Inderal', '40 mg'),
    (35, 'c0de0009-0000-4000-8000-000000000035', 1, 1, 'Hidroclorotiazida', NULL, '25 mg'),
    (36, 'c0de0009-0000-4000-8000-000000000036', 1, 1, 'Furosemida', 'Lasix', '40 mg'),
    (37, 'c0de0009-0000-4000-8000-000000000037', 1, 1, 'Espironolactona', 'Aldactone', '25 mg'),
    (38, 'c0de0009-0000-4000-8000-000000000038', 1, 1, 'Captopril', 'Capoten', '25 mg'),
    (39, 'c0de0009-0000-4000-8000-000000000039', 1, 1, 'Valsartán', 'Diovan', '80 mg'),
    (40, 'c0de0009-0000-4000-8000-000000000040', 1, 1, 'Enalapril', 'Renitec', '10 mg'),
    (41, 'c0de0009-0000-4000-8000-000000000041', 1, 1, 'Atorvastatina', 'Lipitor', '40 mg'),
    (42, 'c0de0009-0000-4000-8000-000000000042', 1, 1, 'Paracetamol', 'Panadol', '500 mg'),
    (43, 'c0de0009-0000-4000-8000-000000000043', 1, 1, 'Amlodipino', 'Norvasc', '5 mg'),
    (44, 'c0de0009-0000-4000-8000-000000000044', 1, 1, 'Nifedipino', 'Adalat', '30 mg'),
    (45, 'c0de0009-0000-4000-8000-000000000045', 1, 1, 'Digoxina', 'Lanoxin', '0.25 mg'),
    (46, 'c0de0009-0000-4000-8000-000000000046', 1, 1, 'Simvastatina', 'Zocor', '20 mg'),
    (47, 'c0de0009-0000-4000-8000-000000000047', 4, 4, 'Insulina glargina', 'Lantus', '100 UI/mL'),
    (48, 'c0de0009-0000-4000-8000-000000000048', 4, 4, 'Insulina NPH', 'Humulin N', '100 UI/mL'),
    (49, 'c0de0009-0000-4000-8000-000000000049', 1, 1, 'Glibenclamida', 'Daonil', '5 mg'),
    (50, 'c0de0009-0000-4000-8000-000000000050', 3, 1, 'Salbutamol', 'Ventolin', '2 mg/5 mL'),
    (51, 'c0de0009-0000-4000-8000-000000000051', 10, 6, 'Budesonida', 'Pulmicort', '200 mcg'),
    (52, 'c0de0009-0000-4000-8000-000000000052', 1, 1, 'Loratadina', 'Clarityne', '10 mg'),
    (53, 'c0de0009-0000-4000-8000-000000000053', 1, 1, 'Cetirizina', 'Zyrtec', '10 mg'),
    (54, 'c0de0009-0000-4000-8000-000000000054', 4, 2, 'Dexametasona', 'Decadron', '4 mg/mL'),
    (55, 'c0de0009-0000-4000-8000-000000000055', 1, 1, 'Prednisona', 'Meticorten', '20 mg'),
    (56, 'c0de0009-0000-4000-8000-000000000056', 5, 5, 'Hidrocortisona', NULL, '1 %'),
    (57, 'c0de0009-0000-4000-8000-000000000057', 1, 1, 'Clonazepam', 'Rivotril', '2 mg'),
    (58, 'c0de0009-0000-4000-8000-000000000058', 2, 1, 'Fluoxetina', 'Prozac', '20 mg'),
    (59, 'c0de0009-0000-4000-8000-000000000059', 5, 5, 'Betametasona', 'Diprosone', '0.05 %'),
    (60, 'c0de0009-0000-4000-8000-000000000060', 5, 5, 'Clotrimazol', 'Canesten', '1 %'),
    (61, 'c0de0009-0000-4000-8000-000000000061', 6, 5, 'Mupirocina', 'Bactroban', '2 %'),
    (62, 'c0de0009-0000-4000-8000-000000000062', 1, 1, 'Famotidina', 'Pepcid', '40 mg'),
    (63, 'c0de0009-0000-4000-8000-000000000063', 1, 1, 'Ondansetrón', 'Zofran', '8 mg'),
    (64, 'c0de0009-0000-4000-8000-000000000064', 1, 1, 'Metoclopramida', 'Plasil', '10 mg'),
    (65, 'c0de0009-0000-4000-8000-000000000065', 2, 1, 'Loperamida', 'Imodium', '2 mg'),
    (66, 'c0de0009-0000-4000-8000-000000000066', 10, 1, 'Sales de rehidratación oral', NULL, '27.9 g'),
    (67, 'c0de0009-0000-4000-8000-000000000067', 3, 1, 'Lactulosa', 'Duphalac', '66.7 %'),
    (68, 'c0de0009-0000-4000-8000-000000000068', 1, 1, 'Sertralina', 'Zoloft', '50 mg'),
    (69, 'c0de0009-0000-4000-8000-000000000069', 1, 1, 'Amitriptilina', 'Tryptanol', '25 mg'),
    (70, 'c0de0009-0000-4000-8000-000000000070', 1, 1, 'Diazepam', 'Valium', '10 mg'),
    (71, 'c0de0009-0000-4000-8000-000000000071', 1, 1, 'Lorazepam', 'Ativan', '2 mg'),
    (72, 'c0de0009-0000-4000-8000-000000000072', 1, 1, 'Risperidona', 'Risperdal', '2 mg'),
    (73, 'c0de0009-0000-4000-8000-000000000073', 1, 1, 'Haloperidol', 'Haldol', '5 mg'),
    (74, 'c0de0009-0000-4000-8000-000000000074', 1, 1, 'Atorvastatina', 'Lipitor', '20 mg'),
    (75, 'c0de0009-0000-4000-8000-000000000075', 1, 1, 'Carbamazepina', 'Tegretol', '200 mg'),
    (76, 'c0de0009-0000-4000-8000-000000000076', 1, 1, 'Ácido valproico', 'Depakine', '500 mg'),
    (77, 'c0de0009-0000-4000-8000-000000000077', 2, 1, 'Fenitoína', 'Epamin', '100 mg'),
    (78, 'c0de0009-0000-4000-8000-000000000078', 1, 1, 'Levetiracetam', 'Keppra', '500 mg'),
    (79, 'c0de0009-0000-4000-8000-000000000079', 2, 1, 'Gabapentina', 'Neurontin', '300 mg'),
    (80, 'c0de0009-0000-4000-8000-000000000080', 1, 1, 'Levodopa + carbidopa', 'Sinemet', '250 mg/25 mg'),
    (81, 'c0de0009-0000-4000-8000-000000000081', 1, 1, 'Ácido fólico', NULL, '5 mg'),
    (82, 'c0de0009-0000-4000-8000-000000000082', 1, 1, 'Sulfato ferroso', NULL, '300 mg'),
    (83, 'c0de0009-0000-4000-8000-000000000083', 1, 1, 'Alprazolam', 'Xanax', '0.5 mg'),
    (84, 'c0de0009-0000-4000-8000-000000000084', 1, 1, 'Metoprolol', 'Lopressor', '50 mg'),
    (85, 'c0de0009-0000-4000-8000-000000000085', 1, 1, 'Sumatriptán', 'Imigran', '50 mg'),
    (86, 'c0de0009-0000-4000-8000-000000000086', 1, 1, 'Levotiroxina', 'Eutirox', '50 mcg'),
    (87, 'c0de0009-0000-4000-8000-000000000087', 1, 1, 'Zolpidem', 'Stilnox', '10 mg');
SELECT setval(pg_get_serial_sequence('"Medication"', 'MedicationId'), (SELECT MAX("MedicationId") FROM "Medication"));

INSERT INTO "MedicationClass" ("MedicationClassId", "MedicationClassCode", "Name", "Description") OVERRIDING SYSTEM VALUE VALUES
    (1, 'c0de0011-0000-4000-8000-000000000001', 'Penicilinas', 'Antibióticos betalactámicos del grupo de las penicilinas.'),
    (2, 'c0de0011-0000-4000-8000-000000000002', 'Cefalosporinas', 'Antibióticos betalactámicos del grupo de las cefalosporinas.'),
    (3, 'c0de0011-0000-4000-8000-000000000003', 'Sulfonamidas', 'Antibióticos derivados de las sulfas.'),
    (4, 'c0de0011-0000-4000-8000-000000000004', 'AINE', 'Antiinflamatorios no esteroideos.'),
    (5, 'c0de0011-0000-4000-8000-000000000005', 'Opioides', 'Analgésicos opioides.'),
    (6, 'c0de0011-0000-4000-8000-000000000006', 'Benzodiacepinas', 'Ansiolíticos e hipnóticos benzodiacepínicos.'),
    (7, 'c0de0011-0000-4000-8000-000000000007', 'Estatinas', 'Inhibidores de la HMG-CoA reductasa.'),
    (8, 'c0de0011-0000-4000-8000-000000000008', 'IECA', 'Inhibidores de la enzima convertidora de angiotensina.'),
    (9, 'c0de0011-0000-4000-8000-000000000009', 'Anticoagulantes y antiagregantes', 'Fármacos que alteran la coagulación o la agregación plaquetaria.'),
    (10, 'c0de0011-0000-4000-8000-000000000010', 'Biguanidas', 'Antidiabéticos tipo biguanida.'),
    (11, 'c0de0011-0000-4000-8000-000000000011', 'Lidocaína', 'Anestésicos locales tipo amida.');
SELECT setval(pg_get_serial_sequence('"MedicationClass"', 'MedicationClassId'), (SELECT MAX("MedicationClassId") FROM "MedicationClass"));

INSERT INTO "MedicationClassMember" ("MedicationClassId", "MedicationId") VALUES
    (1, 1),
    (1, 2),
    (1, 3),
    (2, 6),
    (2, 7),
    (3, 11),
    (4, 19),
    (4, 20),
    (4, 21),
    (4, 22),
    (4, 23),
    (4, 27),
    (5, 25),
    (5, 26),
    (6, 57),
    (6, 83),
    (6, 70),
    (6, 71),
    (7, 41),
    (7, 74),
    (7, 46),
    (8, 40),
    (8, 38),
    (9, 27),
    (9, 28),
    (9, 29),
    (9, 30),
    (10, 33);

INSERT INTO "AllergyMedicationClass" ("AllergyId", "MedicationClassId") VALUES
    (1, 1),
    (2, 1),
    (4, 2),
    (3, 3),
    (12, 4),
    (13, 4),
    (12, 9),
    (14, 5),
    (15, 5),
    (21, 11),
    (22, 8),
    (23, 7),
    (24, 10);

INSERT INTO "MedicationInteraction" ("MedicationInteractionCode", "MedicationClassAId", "MedicationClassBId", "Severity", "Description") VALUES
    ('c0de0012-0000-4000-8000-000000000001', 4, 4, 'Moderate', 'Combinar dos AINE aumenta el riesgo de sangrado gastrointestinal y de daño renal.'),
    ('c0de0012-0000-4000-8000-000000000002', 4, 8, 'Moderate', 'Los AINE reducen el efecto antihipertensivo de los IECA y aumentan el riesgo de daño renal.'),
    ('c0de0012-0000-4000-8000-000000000003', 4, 9, 'Major', 'Mayor riesgo de hemorragia al combinar AINE con anticoagulantes o antiagregantes.'),
    ('c0de0012-0000-4000-8000-000000000004', 5, 6, 'Contraindicated', 'La combinación puede causar depresión respiratoria grave, sedación profunda y muerte.'),
    ('c0de0012-0000-4000-8000-000000000005', 6, 6, 'Moderate', 'Duplicar benzodiacepinas aumenta sedación y riesgo de depresión respiratoria.'),
    ('c0de0012-0000-4000-8000-000000000006', 5, 5, 'Major', 'Duplicar opioides aumenta el riesgo de depresión respiratoria.');

UPDATE "CatalogVersion" SET "Version" = "Version" + 1, "UpdatedAt" = NOW() WHERE "CatalogVersionId" = 1;
