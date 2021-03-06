#!/bin/bash
# Préfix to be ordered here : http://www.interlis.ch/oid/oid_commande_f.php
OIDPREFIX="ch176dc9"

set -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..

# Service to be defined in PG_SERVICE.conf file
PGSERVICE=qgep_poc

while getopts ":p:" opt; do
  case $opt in
    p)
      PGSERVICE=$OPTARG
      echo "-p was triggered, PGSERVICE: $PGSERVICE" >&2
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

# Reframe option to get to MN95 srs. ! Does not work on windows yet!
#psql "service=${PGSERVICE}" -c 'CREATE EXTENSION IF NOT EXISTS fineltra'
psql "service=${PGSERVICE}" -c 'DROP SCHEMA IF EXISTS qgep_od CASCADE'
psql "service=${PGSERVICE}" -c 'DROP SCHEMA IF EXISTS qgep_sys CASCADE'
psql "service=${PGSERVICE}" -c 'DROP SCHEMA IF EXISTS qgep_vl CASCADE'
psql "service=${PGSERVICE}" -c 'DROP SCHEMA IF EXISTS qgep_import CASCADE'
#psql "service=${PGSERVICE}" -c 'DROP SCHEMA IF EXISTS sige_assainissement CASCADE'
#psql "service=${PGSERVICE}" -c 'DROP SCHEMA IF EXISTS sa CASCADE'

# Initialize datamodel
${DIR}/datamodel/scripts/db_setup.sh -s 21781 -p $PGSERVICE -r

# Organisation prefix activation
#Ajout de sigip
psql "service=${PGSERVICE}" -c "INSERT INTO qgep_sys.oid_prefixes (prefix,organization,active) VALUES ('ch176dc9','Sigip',FALSE);"
psql "service=${PGSERVICE}" -c "UPDATE qgep_sys.oid_prefixes SET active=TRUE WHERE prefix='${OIDPREFIX}'"
psql "service=${PGSERVICE}" -c "UPDATE qgep_sys.oid_prefixes SET active=FALSE WHERE prefix<>'${OIDPREFIX}'"

#Deactivate symbology triggers
psql "service=${PGSERVICE}" -c "SELECT qgep_sys.drop_symbology_triggers()"

# Option to restore from backup.
#PGSERVICE=${PGSERVICE} pg_restore --no-owner -d ${PGSERVICE} ${DIR}/migration/dump_topobase_95.backup

# Function first last
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/aggregates_first_last.sql

# Mappings
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/function_hierarchic.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/function_hierarchic_leitungen.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/horizontal_positioning.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/elevation_determination.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/accessibility.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/manhole_function.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/manhole_material.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/special_structure_function.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/usage_current.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/status.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/structure_condition.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/cover_shape.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/cover_fastening.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/cover_material.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/cover_positional_accuracy.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/reach_material.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/reach_material_leitungen.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/function_hydraulic.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/function_hydraulic_leitungen.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/access_aid_kind.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/structure_type.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/node_type.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/node_positional_accuracy.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/se_type.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/mappings/profile_type.sql

# Migration
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/organisations.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/wastewater_structure_cover.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/points_detail.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/profiles.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/pully_reach_channel.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/belmont_reach_channel.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/pully_reach_channel_leitungen.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/belmont_reach_channel_leitungen.sql
#psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/prank_weir.sql
#To be solved

# Recreate views
#psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/90_create_topology.sql
#psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1  -f ${DIR}/datamodel/07_views_for_network_tracking.sql # not sure why we need to rerun this one

# Change owner
PGSERVICE=${PGSERVICE} OWNER=qgep SCHEMA=qgep_od DATABASE=qgep_poc ${DIR}/datamodel/scripts/change_owner.sh

# Détail des ouvrages
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/detail_ouvrages.sql

# Topologie
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/topologie.sql

# Fichiers liés
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/data_media.sql

psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/lien_chambres_pully.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/lien_collecteurs_pully.sql

# Post migration
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/post_migration.sql

# Symbology
psql "service=${PGSERVICE}" -c "SELECT qgep_sys.create_symbology_triggers();"
psql "service=${PGSERVICE}" -c "SELECT qgep_od.update_wastewater_structure_label(NULL, true);"
psql "service=${PGSERVICE}" -c "SELECT qgep_od.update_wastewater_structure_symbology(NULL,true);"

# Update depth
psql "service=${PGSERVICE}" -c "SELECT qgep_od.update_depth(NULL, true);"

# Add Export views

${DIR}/datamodel/view/export/insert_export_views.sh

${DIR}/datamodel/view/pully/insert_sigip_views.sh

# Topologie refresh
psql "service=${PGSERVICE}" -c "REFRESH MATERIALIZED view qgep_od.vw_network_node WITH DATA";
psql "service=${PGSERVICE}" -c "REFRESH MATERIALIZED view qgep_od.vw_network_segment WITH DATA";

# Audit update (Temp for delta test)
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=on -f ${DIR}/migration/audit.sql

