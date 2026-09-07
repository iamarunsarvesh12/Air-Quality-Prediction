# ===========================================================
# AeroSense TN — health_risk_engine.R (Module 5: Health & Disease Risk Engine)
# Authoritative AQI Categorization, Disease Mapping & Safety Guidance
# ===========================================================

HEALTH_DISCLAIMER <- "This health risk analysis provides general environmental risk intelligence based on public air quality indices and is not a medical diagnosis. Individuals with preexisting medical conditions should consult a qualified healthcare professional for clinical advice."

#' Classify AQI into official category
classify_aqi <- function(aqi_val) {
  aqi <- as.numeric(aqi_val)
  
  if (aqi <= 50) {
    list(
      category = "Good",
      color = "#10B981", # Emerald
      bg_color = "#ECFDF5",
      risk_level = "Low",
      summary = "Air quality is satisfactory; air pollution poses little or no risk.",
      general_advice = "Enjoy outdoor activities. Air quality is safe for all groups."
    )
  } else if (aqi <= 100) {
    list(
      category = "Satisfactory / Moderate",
      color = "#0284C7", # Sky Blue
      bg_color = "#F0F9FF",
      risk_level = "Moderate",
      summary = "Air quality is acceptable; minor discomfort for hypersensitive people.",
      general_advice = "Generally suitable for outdoor activities; sensitive individuals should observe mild symptoms."
    )
  } else if (aqi <= 200) {
    list(
      category = "Moderately Polluted",
      color = "#F59E0B", # Amber
      bg_color = "#FFFBEB",
      risk_level = "Moderate-High",
      summary = "May cause breathing discomfort to sensitive people and asthma patients.",
      general_advice = "Sensitive groups should reduce prolonged outdoor exertion."
    )
  } else if (aqi <= 300) {
    list(
      category = "Poor",
      color = "#EF4444", # Red
      bg_color = "#FEF2F2",
      risk_level = "High",
      summary = "Causes breathing discomfort to most people on prolonged outdoor exposure.",
      general_advice = "Wear protective N95 masks outdoors; avoid strenuous cardio workouts outside."
    )
  } else if (aqi <= 400) {
    list(
      category = "Very Poor",
      color = "#8B5CF6", # Purple
      bg_color = "#F5F3FF",
      risk_level = "Very High",
      summary = "Respiratory illness likely on prolonged exposure; severe impact on vulnerable groups.",
      general_advice = "Stay indoors with HEPA air filtration; keep windows and doors securely closed."
    )
  } else {
    list(
      category = "Severe / Hazardous",
      color = "#881337", # Maroon / Deep Crimson
      bg_color = "#FFF1F2",
      risk_level = "Critical / Severe",
      summary = "Emergency health warnings; high risk of severe physiological distress for entire population.",
      general_advice = "Avoid all outdoor physical activity; emergency precautions advised."
    )
  }
}

#' Generate disease risks and actionable health recommendations
#'
#' @param aqi_val Numeric AQI
#' @param primary_pollutant String
#' @param persona Target risk persona
#' @return Comprehensive list of disease risks, recommendations, and disclaimer
analyze_health_risks <- function(aqi_val, primary_pollutant = "PM2.5", persona = "general") {
  classification <- classify_aqi(aqi_val)
  aqi <- as.numeric(aqi_val)
  
  diseases <- list()
  
  # Disease 1: Asthma & Bronchial Hyperresponsiveness
  asthma_risk <- if (aqi <= 50) "Low" else if (aqi <= 100) "Mild" else if (aqi <= 200) "Moderate" else if (aqi <= 300) "High" else "Severe"
  diseases <- append(diseases, list(list(
    name = "Asthma Exacerbation & Bronchospasm",
    risk_level = asthma_risk,
    trigger_pollutants = c("PM2.5", "NO₂", "O₃"),
    symptoms = "Wheezing, shortness of breath, chest tightness, increased bronchodilator inhaler usage.",
    mitigation = "Keep rescue inhaler readily accessible; avoid cold air inhalation during peak traffic hours."
  )))
  
  # Disease 2: Acute Bronchitis & Airway Inflammation
  bronchitis_risk <- if (aqi <= 100) "Low" else if (aqi <= 200) "Moderate" else if (aqi <= 300) "High" else "Severe"
  diseases <- append(diseases, list(list(
    name = "Acute Bronchitis & Upper Airway Inflammation",
    risk_level = bronchitis_risk,
    trigger_pollutants = c("PM10", "SO₂", "NO₂"),
    symptoms = "Persistent throat irritation, coughing with mucus, burning sensation in upper chest.",
    mitigation = "Use warm steam inhalation; wear certified N95 particulate respirator mask outdoors."
  )))
  
  # Disease 3: Cardiovascular Stress & Microvascular Constriction
  cardio_risk <- if (aqi <= 150) "Low" else if (aqi <= 250) "Moderate" else if (aqi <= 350) "High" else "Critical"
  diseases <- append(diseases, list(list(
    name = "Cardiovascular Strain & Endothelial Stress",
    risk_level = cardio_risk,
    trigger_pollutants = c("PM2.5", "CO"),
    symptoms = "Elevated resting blood pressure, heart palpitations, accelerated pulse rate, systemic oxidative stress.",
    mitigation = "Avoid heavy outdoor resistance or endurance training; maintain optimal hydration."
  )))
  
  # Disease 4: COPD Flare-Up
  copd_risk <- if (aqi <= 120) "Low" else if (aqi <= 200) "Moderate" else if (aqi <= 300) "High" else "Critical"
  diseases <- append(diseases, list(list(
    name = "COPD & Chronic Pulmonary Complications",
    risk_level = copd_risk,
    trigger_pollutants = c("PM2.5", "PM10", "O₃"),
    symptoms = "Exertional dyspnea, fatigue, decreased oxygen saturation levels.",
    mitigation = "Maintain indoor HEPA filtration; consult physician if peak flow drops by >15%."
  )))
  
  # Disease 5: Allergic Rhinitis & Ocular Irritation
  rhinitis_risk <- if (aqi <= 80) "Low" else if (aqi <= 180) "Moderate" else "High"
  diseases <- append(diseases, list(list(
    name = "Allergic Rhinitis & Conjunctival Irritation",
    risk_level = rhinitis_risk,
    trigger_pollutants = c("PM10", "Ozone", "SO₂"),
    symptoms = "Watery eyes, nasal congestion, frequent sneezing, itchy palate.",
    mitigation = "Rinse eyes with sterile saline after outdoor exposure; keep car windows closed while commuting."
  )))
  
  # Persona-specific tailored recommendations
  persona_advice <- switch(
    persona,
    "sensitive" = list(
      title = "Sensitive / Asthma Patient Protocol",
      action = "Carry prescribed rescue inhalers at all times. Keep indoor air purifiers running continuously on auto mode.",
      outdoor_limit = if (aqi > 100) "Strictly limit outdoor activity to <15 mins" else "Normal outdoor routine allowed",
      mask_recommendation = if (aqi > 100) "N95 / FFP2 respirator mask mandatory" else "Cloth mask optional"
    ),
    "children_elderly" = list(
      title = "Children & Senior Citizen Protocol",
      action = "Avoid outdoor playgrounds or morning walks during peak pollution hours. Maintain adequate indoor hydration.",
      outdoor_limit = if (aqi > 100) "Limit outdoor exposure; stay in shaded/filtered indoor areas" else "Safe for outdoor playtime",
      mask_recommendation = if (aqi > 150) "Well-fitted child/senior N95 mask" else "None required"
    ),
    "athletes" = list(
      title = "Outdoor Athlete & Runner Protocol",
      action = "High ventilation rates during cardio increase deep lung particulate deposition. Shift training indoors.",
      outdoor_limit = if (aqi > 120) "Shift intense workouts to indoor treadmill/gym" else "Outdoor exercise permitted",
      mask_recommendation = if (aqi > 150) "Sports training mask or move indoors" else "None"
    ),
    "workers" = list(
      title = "Outdoor & Construction Staff Protocol",
      action = "Take regular indoor breaks every 45 minutes in filtered rest areas. Wash face and eyes periodically.",
      outdoor_limit = if (aqi > 200) "Mandatory rotation schedules with filtered resting zones" else "Standard shift hours",
      mask_recommendation = if (aqi > 100) "Heavy-duty N95 / KN95 mask with exhalation valve" else "Dust mask recommended"
    ),
    # Default: General Public
    list(
      title = "General Population Protocol",
      action = "Ventilate indoor spaces during midday when air quality is optimal. Ensure vehicle cabin air recirculation is on.",
      outdoor_limit = if (aqi > 200) "Avoid unnecessary prolonged outdoor exposure" else "Normal daily activities",
      mask_recommendation = if (aqi > 200) "N95 / KN95 mask recommended in heavy traffic" else "No mask required"
    )
  )
  
  list(
    aqi = aqi,
    category = classification$category,
    color = classification$color,
    bg_color = classification$bg_color,
    risk_level = classification$risk_level,
    summary = classification$summary,
    general_advice = classification$general_advice,
    primary_pollutant = primary_pollutant,
    disease_risks = diseases,
    persona_recommendation = persona_advice,
    disclaimer = HEALTH_DISCLAIMER
  )
}
