<?xml version='1.0' encoding='utf-8'?>
<tileset version="1.10" tiledversion="1.12.2" name="h01_layout_objects" tilewidth="32" tileheight="32" tilecount="256" columns="16">
  <properties>
    <property name="assetStatus" value="h01_layout_candidate_batch_001" />
    <property name="occlusionSplit" type="bool" value="true" />
    <property name="sourceBatch" value="h03_estate_pipeline_benchmark_approved" />
    <property name="detailPass" value="h03_spring_detail_batch_004" />
    <property name="aiReferencePixelsUsed" value="false" type="bool" />
    <property name="runtimeIntegrated" value="false" type="bool" />
    <property name="seasonalPass" value="h03_seasons_anomaly_batch_005" />
    <property name="activeSeason" value="spring_layout_review" />
    <property name="activeAnomaly" value="normal" />
    <property name="seasonProfile" value="spring" />
    <property name="anomalyProfile" value="independent_overlay" />
    <property name="artCandidateBatch" value="h01_open_meadow_layout_batch_001" />
    <property name="sourceMapId" value="home_h03_forest_hollow" />
    <property name="targetMapId" value="home_h01_open_meadow" />
    <property name="artRole" value="shared_estate_layout_visual_language" />
    <property name="shippingApproval" type="bool" value="false" />
    <property name="h02SpecificPixelPass" value="false" type="bool" />
  </properties>
  <image source="h01_layout_objects.png" width="512" height="512" />
  <tile id="0" class="tree_component">
    <properties>
      <property name="treeKind" value="evergreen" />
      <property name="renderRole" value="canopy_occlusion" />
    </properties>
  </tile>
  <tile id="1" class="tree_component">
    <properties>
      <property name="treeKind" value="evergreen" />
      <property name="renderRole" value="canopy_occlusion" />
    </properties>
  </tile>
  <tile id="16" class="tree_component">
    <properties>
      <property name="treeKind" value="evergreen" />
      <property name="renderRole" value="canopy_occlusion" />
    </properties>
  </tile>
  <tile id="17" class="tree_component">
    <properties>
      <property name="treeKind" value="evergreen" />
      <property name="renderRole" value="canopy_occlusion" />
    </properties>
  </tile>
  <tile id="32" class="tree_component">
    <properties>
      <property name="treeKind" value="evergreen" />
      <property name="renderRole" value="trunk_collision" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="10" y="8" width="12" height="24" />
    </objectgroup>
  </tile>
  <tile id="33" class="tree_component">
    <properties>
      <property name="treeKind" value="evergreen" />
      <property name="renderRole" value="trunk_collision" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="10" y="8" width="12" height="24" />
    </objectgroup>
  </tile>
  <tile id="2" class="tree_component">
    <properties>
      <property name="treeKind" value="broadleaf" />
      <property name="renderRole" value="canopy_occlusion" />
    </properties>
  </tile>
  <tile id="3" class="tree_component">
    <properties>
      <property name="treeKind" value="broadleaf" />
      <property name="renderRole" value="canopy_occlusion" />
    </properties>
  </tile>
  <tile id="18" class="tree_component">
    <properties>
      <property name="treeKind" value="broadleaf" />
      <property name="renderRole" value="canopy_occlusion" />
    </properties>
  </tile>
  <tile id="19" class="tree_component">
    <properties>
      <property name="treeKind" value="broadleaf" />
      <property name="renderRole" value="canopy_occlusion" />
    </properties>
  </tile>
  <tile id="34" class="tree_component">
    <properties>
      <property name="treeKind" value="broadleaf" />
      <property name="renderRole" value="trunk_collision" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="10" y="8" width="12" height="24" />
    </objectgroup>
  </tile>
  <tile id="35" class="tree_component">
    <properties>
      <property name="treeKind" value="broadleaf" />
      <property name="renderRole" value="trunk_collision" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="10" y="8" width="12" height="24" />
    </objectgroup>
  </tile>
  <tile id="4" class="tree_component">
    <properties>
      <property name="treeKind" value="forked" />
      <property name="renderRole" value="canopy_occlusion" />
    </properties>
  </tile>
  <tile id="5" class="tree_component">
    <properties>
      <property name="treeKind" value="forked" />
      <property name="renderRole" value="canopy_occlusion" />
    </properties>
  </tile>
  <tile id="20" class="tree_component">
    <properties>
      <property name="treeKind" value="forked" />
      <property name="renderRole" value="canopy_occlusion" />
    </properties>
  </tile>
  <tile id="21" class="tree_component">
    <properties>
      <property name="treeKind" value="forked" />
      <property name="renderRole" value="canopy_occlusion" />
    </properties>
  </tile>
  <tile id="36" class="tree_component">
    <properties>
      <property name="treeKind" value="forked" />
      <property name="renderRole" value="trunk_collision" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="10" y="8" width="12" height="24" />
    </objectgroup>
  </tile>
  <tile id="37" class="tree_component">
    <properties>
      <property name="treeKind" value="forked" />
      <property name="renderRole" value="trunk_collision" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="10" y="8" width="12" height="24" />
    </objectgroup>
  </tile>
  <tile id="64" class="removable_resource">
    <properties>
      <property name="resourceKind" value="weed" />
      <property name="clearanceTier" value="light" />
      <property name="clearanceCost" type="int" value="1" />
    </properties>
  </tile>
  <tile id="65" class="removable_resource">
    <properties>
      <property name="resourceKind" value="twig" />
      <property name="clearanceTier" value="light" />
      <property name="clearanceCost" type="int" value="1" />
    </properties>
  </tile>
  <tile id="66" class="removable_resource">
    <properties>
      <property name="resourceKind" value="small_stone" />
      <property name="clearanceTier" value="light" />
      <property name="clearanceCost" type="int" value="1" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="9" y="14" width="15" height="13" />
    </objectgroup>
  </tile>
  <tile id="67" class="removable_resource">
    <properties>
      <property name="resourceKind" value="shrub" />
      <property name="clearanceTier" value="medium" />
      <property name="clearanceCost" type="int" value="2" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="8" y="16" width="17" height="13" />
    </objectgroup>
  </tile>
  <tile id="68" class="removable_resource">
    <properties>
      <property name="resourceKind" value="dense_weed" />
      <property name="clearanceTier" value="medium" />
      <property name="clearanceCost" type="int" value="2" />
    </properties>
  </tile>
  <tile id="69" class="removable_resource">
    <properties>
      <property name="resourceKind" value="boulder" />
      <property name="clearanceTier" value="heavy" />
      <property name="clearanceCost" type="int" value="3" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="5" y="8" width="23" height="22" />
    </objectgroup>
  </tile>
  <tile id="70" class="removable_resource">
    <properties>
      <property name="resourceKind" value="fallen_log" />
      <property name="clearanceTier" value="heavy" />
      <property name="clearanceCost" type="int" value="3" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="3" y="12" width="27" height="15" />
    </objectgroup>
  </tile>
  <tile id="71" class="removable_resource">
    <properties>
      <property name="resourceKind" value="stump" />
      <property name="clearanceTier" value="heavy" />
      <property name="clearanceCost" type="int" value="3" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="8" y="11" width="18" height="19" />
    </objectgroup>
  </tile>
  <tile id="96" class="fence">
    <properties>
      <property name="connectionMaskNESW" type="int" value="0" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="12" y="8" width="8" height="24" />
    </objectgroup>
  </tile>
  <tile id="97" class="fence">
    <properties>
      <property name="connectionMaskNESW" type="int" value="1" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="12" y="8" width="8" height="24" />
    </objectgroup>
  </tile>
  <tile id="98" class="fence">
    <properties>
      <property name="connectionMaskNESW" type="int" value="2" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="12" y="8" width="8" height="24" />
    </objectgroup>
  </tile>
  <tile id="99" class="fence">
    <properties>
      <property name="connectionMaskNESW" type="int" value="3" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="12" y="8" width="8" height="24" />
    </objectgroup>
  </tile>
  <tile id="100" class="fence">
    <properties>
      <property name="connectionMaskNESW" type="int" value="4" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="12" y="8" width="8" height="24" />
    </objectgroup>
  </tile>
  <tile id="101" class="fence">
    <properties>
      <property name="connectionMaskNESW" type="int" value="5" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="12" y="8" width="8" height="24" />
    </objectgroup>
  </tile>
  <tile id="102" class="fence">
    <properties>
      <property name="connectionMaskNESW" type="int" value="6" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="12" y="8" width="8" height="24" />
    </objectgroup>
  </tile>
  <tile id="103" class="fence">
    <properties>
      <property name="connectionMaskNESW" type="int" value="7" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="12" y="8" width="8" height="24" />
    </objectgroup>
  </tile>
  <tile id="104" class="fence">
    <properties>
      <property name="connectionMaskNESW" type="int" value="8" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="12" y="8" width="8" height="24" />
    </objectgroup>
  </tile>
  <tile id="105" class="fence">
    <properties>
      <property name="connectionMaskNESW" type="int" value="9" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="12" y="8" width="8" height="24" />
    </objectgroup>
  </tile>
  <tile id="106" class="fence">
    <properties>
      <property name="connectionMaskNESW" type="int" value="10" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="12" y="8" width="8" height="24" />
    </objectgroup>
  </tile>
  <tile id="107" class="fence">
    <properties>
      <property name="connectionMaskNESW" type="int" value="11" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="12" y="8" width="8" height="24" />
    </objectgroup>
  </tile>
  <tile id="108" class="fence">
    <properties>
      <property name="connectionMaskNESW" type="int" value="12" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="12" y="8" width="8" height="24" />
    </objectgroup>
  </tile>
  <tile id="109" class="fence">
    <properties>
      <property name="connectionMaskNESW" type="int" value="13" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="12" y="8" width="8" height="24" />
    </objectgroup>
  </tile>
  <tile id="110" class="fence">
    <properties>
      <property name="connectionMaskNESW" type="int" value="14" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="12" y="8" width="8" height="24" />
    </objectgroup>
  </tile>
  <tile id="111" class="fence">
    <properties>
      <property name="connectionMaskNESW" type="int" value="15" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="12" y="8" width="8" height="24" />
    </objectgroup>
  </tile>
  <tile id="128" class="season_overlay">
    <properties>
      <property name="season" value="spring" />
    </properties>
  </tile>
  <tile id="129" class="season_overlay">
    <properties>
      <property name="season" value="summer" />
    </properties>
  </tile>
  <tile id="130" class="season_overlay">
    <properties>
      <property name="season" value="autumn" />
    </properties>
  </tile>
  <tile id="131" class="season_overlay">
    <properties>
      <property name="season" value="winter" />
    </properties>
  </tile>
  <tile id="144" class="anomaly_visual_overlay">
    <properties>
      <property name="anomalyLevel" value="light" />
      <property name="controlledPartialAlpha" type="bool" value="true" />
      <property name="anomalyVisualOnly" type="bool" value="true" />
      <property name="authoritativeCollision" type="bool" value="false" />
      <property name="localizedMarkerVariant" type="bool" value="false" />
      <property name="anomalyReadabilityRevision" type="int" value="2" />
    </properties>
  </tile>
  <tile id="145" class="anomaly_visual_overlay">
    <properties>
      <property name="anomalyLevel" value="medium" />
      <property name="controlledPartialAlpha" type="bool" value="true" />
      <property name="anomalyVisualOnly" type="bool" value="true" />
      <property name="authoritativeCollision" type="bool" value="false" />
      <property name="localizedMarkerVariant" type="bool" value="false" />
      <property name="anomalyReadabilityRevision" type="int" value="2" />
    </properties>
  </tile>
  <tile id="160" class="effect_animation">
    <properties>
      <property name="effect" value="chimney_smoke" />
      <property name="controlledPartialAlpha" type="bool" value="true" />
    </properties>
    <animation>
      <frame tileid="160" duration="220" />
      <frame tileid="161" duration="220" />
      <frame tileid="162" duration="220" />
      <frame tileid="163" duration="220" />
    </animation>
  </tile>
  <wangsets>
    <wangset name="Low Weathered Fence" tile="-1">
      <wangcolor name="Low Weathered Fence" color="#694b31" tile="111" probability="1" />
      <wangtile tileid="96" wangid="0,0,0,0,0,0,0,0" />
      <wangtile tileid="97" wangid="0,1,0,0,0,0,0,0" />
      <wangtile tileid="98" wangid="0,0,0,1,0,0,0,0" />
      <wangtile tileid="99" wangid="0,1,0,1,0,0,0,0" />
      <wangtile tileid="100" wangid="0,0,0,0,0,1,0,0" />
      <wangtile tileid="101" wangid="0,1,0,0,0,1,0,0" />
      <wangtile tileid="102" wangid="0,0,0,1,0,1,0,0" />
      <wangtile tileid="103" wangid="0,1,0,1,0,1,0,0" />
      <wangtile tileid="104" wangid="0,0,0,0,0,0,0,1" />
      <wangtile tileid="105" wangid="0,1,0,0,0,0,0,1" />
      <wangtile tileid="106" wangid="0,0,0,1,0,0,0,1" />
      <wangtile tileid="107" wangid="0,1,0,1,0,0,0,1" />
      <wangtile tileid="108" wangid="0,0,0,0,0,1,0,1" />
      <wangtile tileid="109" wangid="0,1,0,0,0,1,0,1" />
      <wangtile tileid="110" wangid="0,0,0,1,0,1,0,1" />
      <wangtile tileid="111" wangid="0,1,0,1,0,1,0,1" />
    </wangset>
  </wangsets>
  <tile id="146" class="anomaly_visual_overlay">
    <properties>
      <property name="anomalyVisualOnly" type="bool" value="true" />
      <property name="authoritativeCollision" type="bool" value="false" />
      <property name="anomalyLevel" value="light" />
      <property name="localizedMarkerVariant" type="bool" value="true" />
      <property name="anomalyReadabilityRevision" type="int" value="2" />
    </properties>
  </tile>
  <tile id="147" class="anomaly_visual_overlay">
    <properties>
      <property name="anomalyVisualOnly" type="bool" value="true" />
      <property name="authoritativeCollision" type="bool" value="false" />
      <property name="anomalyLevel" value="medium" />
      <property name="localizedMarkerVariant" type="bool" value="true" />
      <property name="anomalyReadabilityRevision" type="int" value="2" />
    </properties>
  </tile>
  <tile id="148" class="anomaly_visual_overlay">
    <properties>
      <property name="anomalyVisualOnly" type="bool" value="true" />
      <property name="authoritativeCollision" type="bool" value="false" />
      <property name="anomalyLevel" value="light" />
      <property name="localizedMarkerVariant" type="bool" value="false" />
      <property name="anomalyReadabilityRevision" type="int" value="2" />
    </properties>
  </tile>
  <tile id="149" class="anomaly_visual_overlay">
    <properties>
      <property name="anomalyVisualOnly" type="bool" value="true" />
      <property name="authoritativeCollision" type="bool" value="false" />
      <property name="anomalyLevel" value="light" />
      <property name="localizedMarkerVariant" type="bool" value="false" />
      <property name="anomalyReadabilityRevision" type="int" value="2" />
    </properties>
  </tile>
  <tile id="150" class="anomaly_visual_overlay">
    <properties>
      <property name="anomalyVisualOnly" type="bool" value="true" />
      <property name="authoritativeCollision" type="bool" value="false" />
      <property name="anomalyLevel" value="light" />
      <property name="localizedMarkerVariant" type="bool" value="false" />
      <property name="anomalyReadabilityRevision" type="int" value="2" />
    </properties>
  </tile>
  <tile id="151" class="anomaly_visual_overlay">
    <properties>
      <property name="anomalyVisualOnly" type="bool" value="true" />
      <property name="authoritativeCollision" type="bool" value="false" />
      <property name="anomalyLevel" value="light" />
      <property name="localizedMarkerVariant" type="bool" value="true" />
      <property name="anomalyReadabilityRevision" type="int" value="2" />
    </properties>
  </tile>
  <tile id="152" class="anomaly_visual_overlay">
    <properties>
      <property name="anomalyVisualOnly" type="bool" value="true" />
      <property name="authoritativeCollision" type="bool" value="false" />
      <property name="anomalyLevel" value="medium" />
      <property name="localizedMarkerVariant" type="bool" value="false" />
      <property name="anomalyReadabilityRevision" type="int" value="2" />
    </properties>
  </tile>
  <tile id="153" class="anomaly_visual_overlay">
    <properties>
      <property name="anomalyVisualOnly" type="bool" value="true" />
      <property name="authoritativeCollision" type="bool" value="false" />
      <property name="anomalyLevel" value="medium" />
      <property name="localizedMarkerVariant" type="bool" value="false" />
      <property name="anomalyReadabilityRevision" type="int" value="2" />
    </properties>
  </tile>
  <tile id="154" class="anomaly_visual_overlay">
    <properties>
      <property name="anomalyVisualOnly" type="bool" value="true" />
      <property name="authoritativeCollision" type="bool" value="false" />
      <property name="anomalyLevel" value="medium" />
      <property name="localizedMarkerVariant" type="bool" value="false" />
      <property name="anomalyReadabilityRevision" type="int" value="2" />
    </properties>
  </tile>
  <tile id="155" class="anomaly_visual_overlay">
    <properties>
      <property name="anomalyVisualOnly" type="bool" value="true" />
      <property name="authoritativeCollision" type="bool" value="false" />
      <property name="anomalyLevel" value="medium" />
      <property name="localizedMarkerVariant" type="bool" value="true" />
      <property name="anomalyReadabilityRevision" type="int" value="2" />
    </properties>
  </tile>
  <tile id="156" class="anomaly_visual_overlay">
    <properties>
      <property name="anomalyVisualOnly" type="bool" value="true" />
      <property name="authoritativeCollision" type="bool" value="false" />
      <property name="anomalyLevel" value="medium" />
      <property name="localizedMarkerVariant" type="bool" value="false" />
      <property name="anomalyReadabilityRevision" type="int" value="2" />
    </properties>
  </tile>
  <tile id="157" class="anomaly_visual_overlay">
    <properties>
      <property name="anomalyVisualOnly" type="bool" value="true" />
      <property name="authoritativeCollision" type="bool" value="false" />
      <property name="anomalyLevel" value="medium" />
      <property name="localizedMarkerVariant" type="bool" value="false" />
      <property name="anomalyReadabilityRevision" type="int" value="2" />
    </properties>
  </tile>
  <tile id="158" class="anomaly_visual_overlay">
    <properties>
      <property name="anomalyVisualOnly" type="bool" value="true" />
      <property name="authoritativeCollision" type="bool" value="false" />
      <property name="anomalyLevel" value="light" />
      <property name="localizedMarkerVariant" type="bool" value="true" />
      <property name="anomalyReadabilityRevision" type="int" value="2" />
    </properties>
  </tile>
  <tile id="159" class="anomaly_visual_overlay">
    <properties>
      <property name="anomalyVisualOnly" type="bool" value="true" />
      <property name="authoritativeCollision" type="bool" value="false" />
      <property name="anomalyLevel" value="medium" />
      <property name="localizedMarkerVariant" type="bool" value="true" />
      <property name="anomalyReadabilityRevision" type="int" value="2" />
    </properties>
  </tile>
  <tile id="72" class="reed_cluster">
    <properties>
      <property name="region" value="h02_braided_river" />
      <property name="placement" value="water_edge" />
    </properties>
  </tile>
  <tile id="73" class="reed_cluster">
    <properties>
      <property name="region" value="h02_braided_river" />
      <property name="placement" value="water_edge_dense" />
    </properties>
  </tile>
  <tile id="74" class="channel_marker">
    <properties>
      <property name="region" value="h02_braided_river" />
      <property name="collision" type="bool" value="false" />
    </properties>
  </tile>
  <tile id="75" class="driftwood">
    <properties>
      <property name="region" value="h02_braided_river" />
      <property name="removable" type="bool" value="true" />
    </properties>
  </tile>
  <tile id="76" class="ford_marker">
    <properties>
      <property name="region" value="h02_braided_river" />
      <property name="collision" type="bool" value="false" />
    </properties>
  </tile>
  <tile id="77" class="water_gauge">
    <properties>
      <property name="region" value="h02_braided_river" />
      <property name="interactive" type="bool" value="true" />
    </properties>
  </tile>
  <tile id="78" class="dock_plank">
    <properties>
      <property name="region" value="h02_braided_river" />
      <property name="collision" type="bool" value="false" />
    </properties>
  </tile>
  <tile id="79" class="sluice_marker">
    <properties>
      <property name="region" value="h02_braided_river" />
      <property name="interactive" type="bool" value="true" />
    </properties>
  </tile>
</tileset>