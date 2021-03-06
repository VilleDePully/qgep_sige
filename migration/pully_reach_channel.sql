﻿-- compute geometry from pully_ass.aw_haltung_geo
WITH haltungen_geo AS (
SELECT 
  gid, 
  first(z1) as rp_from_level, 
  last(z1) as rp_to_level, 
--  ST_Fineltra(St_SetSRID(ST_GeomFromText('LINESTRINGZ('||string_agg(y1::varchar||' '||x1::varchar||' '||coalesce(z1,0)::varchar, ',' ORDER BY seq)||')'),21781), 'chenyx06.chenyx06_triangles', 'the_geom_lv03', 'the_geom_lv95')::Geometry(LinestringZ,2056) AS geometry 
  ST_SetSRID(ST_GeomFromText('LINESTRINGZ('||string_agg(y1::varchar||' '||x1::varchar||' '||coalesce(z1,0)::varchar, ',' ORDER BY seq)||')'), 21781) AS geometry
FROM pully_ass.aw_haltung_geo 
GROUP BY gid)

INSERT INTO qgep_od.vw_qgep_reach(
  --Reach
  clear_height,
  width,
  material,
  length_effective,
  _slope_per_mill,
  progression_geometry,
  elevation_determination,
  horizontal_positioning,
  fk_pipe_profile,
  --Channel
  ch_function_hierarchic,
  ch_function_hydraulic,
  ch_pipe_length,
  ch_usage_current,
  --Wastewater Structure
  ws_status,
  ws_year_of_construction,
  ws_fk_owner,
  ws_identifier,
  remark, --moved to reach
  ws_structure_condition,
  ws_pully_controle_video_date,
  ws_pully_controle_terrain_date,
  ws_pully_id_topobase,
  ws_pully_table_topobase,
  ws_pully_db_topobase,
  ws_pully_validation,
  --Network element
  identifier,
  --Reach point from
  rp_from_identifier,
  rp_from_level,
  --Reach point to
  rp_to_identifier,
  rp_to_level
  --Active maintenance event
)
SELECT
  --Reach
  profil_breite, --clear_height
  profil_hoehe, -- width (when not isometric)
  rm.new, -- material
  ST_3dLength(geometry), -- length_effective
  gefaelle, --slope per mill
  geometry, -- progression_geometry
  ed.new,
  COALESCE(hp.new, 5379),
  pp.obj_id,
  --Channel
  fh.new, -- function_hierarchic
  fhy.new, -- function_hydraulic
  stranglaenge, -- pipe_length
  uc.new, -- usage_current
  --Wastewater Structure
  st.new, -- status
  baujahr, -- year_of_construction
  haltung.id_eigentumsverhaeltnis, -- fk_owner
  haltung.name, --ws_identifier
  bemerkung, --remark
  rst.new, --reach condition
  haltung.p_controle_video_date,
  haltung.p_controle_terrain_date,
  haltung.fid,
  'AW_HALTUNG',
  'PULLY_ASS',
  true,
  --Network element
  haltung.name,
  --(Automatic)
  --Reach point from
  fid_vs,
  rp_from_level,
  --Reach point to
  fid_bs,
  rp_to_level

FROM pully_ass.aw_haltung haltung
LEFT JOIN haltungen_geo geom on geom.gid = haltung.gid
LEFT JOIN migration.map_reach_structure_condition rst ON haltung.p_etat_id = rst.old
LEFT JOIN migration.map_function_hierarchic fh ON haltung.id_funktion_hierarch = fh.old --OR (fh.old IS NULL AND haltung.id_funktion_hierarch IS NULL)
LEFT JOIN migration.map_horizontal_positioning hp ON haltung.id_lagegenauigkeit = hp.old
LEFT JOIN migration.map_usage_current uc ON haltung.id_nutzungs_art = uc.old
-- Join the profile based on it's type and the height/width-ratio
-- This code has to match the code in profiles.sql
LEFT JOIN migration.map_profile_type mpt ON mpt.old = haltung.id_profilart
LEFT JOIN qgep_od.pipe_profile pp ON pp.profile_type = mpt.new
  AND pp.height_width_ratio = COALESCE(round(NULLIF(haltung.profil_hoehe, 0)/haltung.profil_breite, 2),1)
LEFT JOIN migration.map_reach_material rm ON haltung.id_material = rm.old
LEFT JOIN migration.map_function_hydraulic fhy ON haltung.id_funktion_hydrau = fhy.old
LEFT JOIN migration.map_elevation_determination ed ON haltung.id_hoehengenauigkeit = ed.old
LEFT JOIN migration.map_status st ON haltung.id_status = st.old
WHERE ST_3dLength(geometry) IS NOT NULL;

/* Deleted items have been filtered at export
WHERE COALESCE(haltung.deleted, 0) = 0;*/
