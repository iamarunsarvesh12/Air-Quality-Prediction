# ===========================================================
# AeroSense TN — health_risk_engine.R (Module 5: Health & Disease Risk Engine)
# Authoritative Indian CPCB AQI Categorization, Disease Risk Intelligence & Safety Guidance
# ===========================================================

HEALTH_DISCLAIMER <- "This environmental health assessment provides epidemiological and environmental risk intelligence based on the Indian National Air Quality Index (NAQI/CPCB) and atmospheric pollutant concentrations. It does not constitute a personal medical diagnosis or clinical prognosis. Individuals with preexisting respiratory, cardiovascular, or other medical conditions should consult a licensed healthcare professional for clinical advice."

# Path resolution for aqi_calculator
get_health_script_dir <- function() {
  candidates <- c("backend", ".", file.path(getwd(), "backend"), "..")
  for (c in candidates) {
    if (file.exists(file.path(c, "aqi_calculator.R"))) return(c)
  }
  "."
}
h_dir <- get_health_script_dir()
source(file.path(h_dir, "aqi_calculator.R"), local = TRUE)

#' Classify AQI into official Indian NAQI category
classify_aqi <- function(aqi_val) {
  classify_indian_aqi(aqi_val)
}

#' Generate disease risks and actionable health recommendations based on Indian AQI & Dominant Pollutant
#'
#' @param aqi_val Numeric AQI
#' @param primary_pollutant String dominant pollutant
#' @param persona Target risk persona ("general", "sensitive", "children_elderly", "athletes", "workers")
#' @return Comprehensive list of disease risks, recommendations, and disclaimer
analyze_health_risks <- function(aqi_val, primary_pollutant = "PM2.5", persona = "general") {
  classification <- classify_indian_aqi(aqi_val)
  aqi <- if (!is.null(aqi_val) && !is.na(aqi_val)) as.numeric(aqi_val) else 50
  
  diseases <- list()
  
  # 1. Asthma & Bronchospasm Exacerbation
  asthma_risk <- if (aqi <= 50) "Low" else if (aqi <= 100) "Mild" else if (aqi <= 200) "Moderate" else if (aqi <= 300) "High" else "Severe"
  diseases <- append(diseases, list(list(
    name = "Asthma Exacerbation & Bronchospasm",
    risk_level = asthma_risk,
    trigger_pollutants = c("PM2.5", "NO₂", "O₃"),
    symptoms = "Wheezing, chest tightness, coughing spasms, increased bronchodilator rescue inhaler requirements.",
    mitigation = "Keep rescue inhaler readily accessible. Avoid cold air and outdoor exertion during peak traffic hours."
  )))
  
  # 2. Acute Bronchitis & Airway Inflammation
  bronchitis_risk <- if (aqi <= 100) "Low" else if (aqi <= 200) "Moderate" else if (aqi <= 300) "High" else "Severe"
  diseases <- append(diseases, list(list(
    name = "Acute Bronchitis & Airway Inflammation",
    risk_level = bronchitis_risk,
    trigger_pollutants = c("PM10", "SO₂", "NO₂"),
    symptoms = "Persistent throat tickling, mucus hypersecretion, retrosternal burning sensation on deep inhalation.",
    mitigation = "Use warm humidification/steam inhalation; wear certified N95 respirator mask outdoors when AQI > 100."
  )))
  
  # 3. Cardiovascular Strain & Endothelial Stress
  cardio_risk <- if (aqi <= 100) "Low" else if (aqi <= 200) "Mild" else if (aqi <= 300) "Moderate" else if (aqi <= 400) "High" else "Critical"
  diseases <- append(diseases, list(list(
    name = "Cardiovascular Strain & Endothelial Stress",
    risk_level = cardio_risk,
    trigger_pollutants = c("PM2.5", "CO"),
    symptoms = "Transient elevated blood pressure, autonomic heart rate elevation, systemic inflammatory markers.",
    mitigation = "Avoid vigorous outdoor aerobic exertion; stay well hydrated and minimize exposure near heavy freight corridors."
  )))
  
  # 4. COPD & Chronic Pulmonary Complications
  copd_risk <- if (aqi <= 100) "Low" else if (aqi <= 200) "Moderate" else if (aqi <= 300) "High" else "Critical"
  diseases <- append(diseases, list(list(
    name = "COPD Vulnerability & Exertional Dyspnea",
    risk_level = copd_risk,
    trigger_pollutants = c("PM2.5", "PM10", "O₃"),
    symptoms = "Exercise intolerance, breathlessness with minor movement, reduced peripheral oxygen saturation.",
    mitigation = "Maintain indoor HEPA filtration. Follow prescribed pulmonary action plan and monitor peak expiratory flow."
  )))
  
  # 5. Allergic Rhinitis & Ocular Irritation
  rhinitis_risk <- if (aqi <= 80) "Low" else if (aqi <= 180) "Moderate" else "High"
  diseases <- append(diseases, list(list(
    name = "Allergic Rhinitis & Conjunctival Irritation",
    risk_level = rhinitis_risk,
    trigger_pollutants = c("PM10", "O₃", "SO₂"),
    symptoms = "Lacrimation (watery eyes), conjunctival injection, nasal congestion, repetitive sneezing.",
    mitigation = "Rinse eyes with isotonic saline solution after exposure; close vehicle vents and windows during transit."
  )))
  
  # Persona-specific tailored recommendations
  persona_advice <- switch(
    persona,
    "sensitive" = list(
      title = "Sensitive / Asthma Patient Guidance",
      action = if (aqi > 100) "Carry prescribed rescue inhalers at all times. Run indoor air purification continuously on auto mode." else "Normal routines permitted with standard preventative care.",
      outdoor_limit = if (aqi > 200) "Stay indoors; avoid all outdoor exertion" else if (aqi > 100) "Limit outdoor activity to essential tasks only" else "Normal outdoor routine allowed",
      mask_recommendation = if (aqi > 100) "Well-fitted N95 / FFP2 respirator mask mandatory outdoors" else "Mask optional"
    ),
    "children_elderly" = list(
      title = "Children & Senior Citizen Guidance",
      action = if (aqi > 100) "Avoid morning walks and school outdoor sports during peak pollution windows. Maintain adequate indoor hydration." else "Safe for outdoor playtime and recreation.",
      outdoor_limit = if (aqi > 200) "Strictly avoid outdoor playgrounds and morning walks" else if (aqi > 100) "Limit outdoor play; prefer indoor shaded areas" else "Safe for outdoor playtime",
      mask_recommendation = if (aqi > 150) "Child/Senior sized particulate filter mask" else "None required"
    ),
    "athletes" = list(
      title = "Outdoor Athlete & Runner Guidance",
      action = if (aqi > 100) "Elevated ventilation rate during cardio increases deep alveolar particulate deposition. Shift training indoors." else "Optimal conditions for endurance and interval training.",
      outdoor_limit = if (aqi > 200) "Zero outdoor cardio; complete workouts in indoor gyms" else if (aqi > 100) "Shift intense cardio indoors; restrict outdoor training to light walks" else "Full outdoor endurance training permitted",
      mask_recommendation = if (aqi > 150) "Sports training mask or relocate indoors" else "None"
    ),
    "workers" = list(
      title = "Outdoor Worker & Commuter Guidance",
      action = if (aqi > 100) "Provide hydration stations and scheduled rest breaks in filtered indoor rest areas." else "Standard occupational outdoor conditions.",
      outdoor_limit = if (aqi > 200) "Take frequent indoor rest breaks; rotate shifts away from heavy traffic" else "Standard shift hours permitted",
      mask_recommendation = if (aqi > 100) "Employer-provided N95 / FFP2 respirators recommended" else "Standard dust protection"
    ),
    # Default: General Public
    list(
      title = "General Population Guidance",
      action = if (aqi > 200) "Keep residential doors and windows closed. Use mechanical HEPA filtration if available." else if (aqi > 100) "Sensitive individuals should take rest breaks during prolonged outdoor exertion." else "Air quality is satisfactory. Enjoy regular outdoor activities.",
      outdoor_limit = if (aqi > 300) "Avoid non-essential outdoor travel" else if (aqi > 200) "Reduce prolonged outdoor exertion" else "Standard outdoor routines permitted",
      mask_recommendation = if (aqi > 200) "N95 mask recommended outdoors" else "None required"
    )
  )
  
  list(
    category = classification$category,
    color = classification$color,
    bg_color = classification$bg_color,
    risk_level = classification$risk_level,
    summary = classification$description,
    general_advice = sprintf("Primary driver: %s. %s", primary_pollutant, classification$description),
    disease_risks = diseases,
    persona_recommendation = persona_advice,
    disclaimer = HEALTH_DISCLAIMER
  )
}
