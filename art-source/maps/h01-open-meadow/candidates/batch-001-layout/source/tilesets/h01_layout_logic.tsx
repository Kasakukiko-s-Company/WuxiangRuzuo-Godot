<?xml version='1.0' encoding='utf-8'?>
<tileset version="1.10" tiledversion="1.12.2" name="h01_layout_logic" tilewidth="32" tileheight="32" tilecount="16" columns="16">
  <properties>
    <property name="assetStatus" value="h01_layout_candidate_batch_001" />
    <property name="artCandidateBatch" value="h01_open_meadow_layout_batch_001" />
    <property name="targetMapId" value="home_h01_open_meadow" />
    <property name="logicOnly" type="bool" value="true" />
    <property name="runtimeIntegrated" type="bool" value="false" />
    <property name="converterRequired" type="bool" value="true" />
    <property name="shippingApproval" type="bool" value="false" />
    <property name="artRole" value="shared_estate_layout_visual_language" />
    <property name="h02SpecificPixelPass" type="bool" value="false" />
  </properties>
  <image source="h01_layout_logic.png" width="512" height="32" />
  <tile id="0" class="collision_water">
    <properties>
      <property name="semanticId" value="collision_water" />
      <property name="godotDisposition" value="physics:add_full_tile" />
      <property name="operation" value="add" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="0" y="0" width="32" height="32" />
    </objectgroup>
  </tile>
  <tile id="1" class="farmable">
    <properties>
      <property name="semanticId" value="farmable" />
      <property name="godotDisposition" value="custom_data:farmable" />
      <property name="operation" value="set_true" />
    </properties>
  </tile>
  <tile id="2" class="buildable_free">
    <properties>
      <property name="semanticId" value="buildable_free" />
      <property name="godotDisposition" value="custom_data:buildable_free" />
      <property name="operation" value="set_true" />
    </properties>
  </tile>
  <tile id="3" class="buildable_reserved">
    <properties>
      <property name="semanticId" value="buildable_reserved" />
      <property name="godotDisposition" value="custom_data:buildable_reserved" />
      <property name="operation" value="set_true" />
    </properties>
  </tile>
  <tile id="4" class="no_build">
    <properties>
      <property name="semanticId" value="no_build" />
      <property name="godotDisposition" value="custom_data:no_build" />
      <property name="operation" value="set_true" />
    </properties>
  </tile>
  <tile id="5" class="bridge_permanent">
    <properties>
      <property name="semanticId" value="bridge_permanent" />
      <property name="godotDisposition" value="water_authority:remove_collision_and_fishable" />
      <property name="operation" value="remove_water_collision_and_fishable" />
    </properties>
  </tile>
  <tile id="6" class="crossing_override">
    <properties>
      <property name="semanticId" value="crossing_override" />
      <property name="godotDisposition" value="water_authority:remove_collision_fishable_and_ecology_when_state_active" />
      <property name="operation" value="remove_water_collision_fishable_and_ecology_when_active" />
      <property name="removesFishableEligibility" type="bool" value="true" />
      <property name="removesFishingEcologyProfile" type="bool" value="true" />
    </properties>
  </tile>
  <tile id="7" class="high_water_collision_add">
    <properties>
      <property name="semanticId" value="high_water_collision_add" />
      <property name="godotDisposition" value="collision:add_water_when_high" />
      <property name="operation" value="stateful_add" />
    </properties>
    <objectgroup draworder="index" id="1">
      <object id="1" x="0" y="0" width="32" height="32" />
    </objectgroup>
  </tile>
  <tile id="8" class="high_water_fishable_add">
    <properties>
      <property name="semanticId" value="high_water_fishable_add" />
      <property name="godotDisposition" value="custom_data:fishable_when_high" />
      <property name="operation" value="stateful_add" />
    </properties>
  </tile>
  <tile id="9" class="high_water_farmable_remove">
    <properties>
      <property name="semanticId" value="high_water_farmable_remove" />
      <property name="godotDisposition" value="custom_data:farmable_when_high" />
      <property name="operation" value="stateful_remove" />
    </properties>
  </tile>
  <tile id="10" class="high_water_buildable_remove">
    <properties>
      <property name="semanticId" value="high_water_buildable_remove" />
      <property name="godotDisposition" value="custom_data:buildable_when_high" />
      <property name="operation" value="stateful_remove" />
    </properties>
  </tile>
  <tile id="11" class="background_scenery">
    <properties>
      <property name="semanticId" value="background_scenery" />
      <property name="godotDisposition" value="access:exclude_from_player_land" />
      <property name="operation" value="exclude" />
    </properties>
  </tile>
  <tile id="12" class="fishing_ecology_pond_brook">
    <properties>
      <property name="semanticId" value="fish_ecology.h01.pond_brook" />
      <property name="godotDisposition" value="custom_data:fishing_ecology_zone" />
      <property name="operation" value="set_profile" />
    </properties>
  </tile>
  <tile id="13" class="fishing_ecology_south_stream">
    <properties>
      <property name="semanticId" value="fish_ecology.h01.south_stream" />
      <property name="godotDisposition" value="custom_data:fishing_ecology_zone" />
      <property name="operation" value="set_profile" />
    </properties>
  </tile>
</tileset>