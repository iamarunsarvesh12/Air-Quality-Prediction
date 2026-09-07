# ===========================================================
# AirSense — disease_mapping.R (Module 7: Disease Mapping)
# Maps an AQI category to possible health effects and
# preventive recommendations, using health_data.csv as the
# source of truth (falls back to built-in defaults if missing).
# ===========================================================

library(readr)
library(dplyr)

# Helper to resolve paths regardless of execution directory
resolve_path <- function(filename) {
  if (file.exists(filename)) return(filename)
  bpath <- file.path("backend", filename)
  if (file.exists(bpath)) return(bpath)
  upath <- file.path("..", filename)
  if (file.exists(upath)) return(upath)
  ubpath <- file.path("..", "backend", filename)
  if (file.exists(ubpath)) return(ubpath)
  filename
}

DEFAULT_HEALTH_MAP <- list(
  "Good" = list(
    effects = list("No significant health risk."),
    recommendations = list("Enjoy normal outdoor activities.")
  ),
  "Moderate" = list(
    effects = list("Mild respiratory irritation possible for unusually sensitive individuals."),
    recommendations = list("Sensitive individuals should reduce prolonged or heavy exertion outdoors.")
  ),
  "Unhealthy for Sensitive Groups" = list(
    effects = list("Increased likelihood of respiratory symptoms in children, elderly, and people with asthma or heart disease."),
    recommendations = list("Sensitive groups should limit prolonged outdoor exertion.",
                         "Keep quick-relief medication on hand if you have asthma.")
  ),
  "Unhealthy" = list(
    effects = list("Increased respiratory effects in the general population.",
                "Aggravation of heart or lung disease."),
    recommendations = list("Reduce prolonged outdoor exertion.",
                         "Consider wearing a mask (N95) outdoors.")
  ),
  "Very Unhealthy" = list(
    effects = list("Significant aggravation of heart or lung disease.",
                "Premature mortality risk in people with cardiopulmonary disease and the elderly."),
    recommendations = list("Avoid outdoor exertion.", "Keep windows closed and use an air purifier indoors.")
  ),
  "Hazardous" = list(
    effects = list("Serious risk of respiratory effects for the entire population."),
    recommendations = list("Remain indoors and keep activity levels low.",
                         "Use an air purifier and avoid all outdoor exertion.")
  )
)

#' Get comprehensive safety advice, gear recommendations, and persona risk profiles.
#'
#' @param category AQI category string.
#' @return A list with gear requirements, action checklist, and persona-specific advice.
get_safety_advisor <- function(category) {
  if (category == "Good") {
    list(
      mask = "No mask required",
      purifier = "Natural ventilation recommended",
      windows = "Keep windows open for fresh air",
      exertionLimit = "Unlimited outdoor physical activity",
      actionChecklist = list(
        "Open windows to ventilate indoor living spaces",
        "Enjoy outdoor workouts, sports, and recreation",
        "Maintain regular daily routines safely"
      ),
      groupAdvice = list(
        general = "Air quality is satisfactory and poses little or no risk to health.",
        sensitive = "Great air quality! Safe for all outdoor activities and exercise.",
        children_elderly = "Encourage outdoor play, walks, and outdoor sports.",
        athletes = "Ideal conditions for peak outdoor cardio and high-intensity training.",
        workers = "Standard work conditions with zero respiratory restriction."
      )
    )
  } else if (category == "Moderate") {
    list(
      mask = "Optional for unusually sensitive individuals",
      purifier = "Low speed or intermittent HEPA filtration",
      windows = "Open during early morning and late evening",
      exertionLimit = "Moderate outdoor exertion allowed",
      actionChecklist = list(
        "Monitor AQI forecasts if planning extended outdoor trips",
        "Close windows during peak heavy traffic hours",
        "Drink plenty of water to maintain moist respiratory airways"
      ),
      groupAdvice = list(
        general = "Acceptable air quality for most individuals.",
        sensitive = "Take rest breaks during heavy outdoor exertion if coughing or throat irritation occurs.",
        children_elderly = "Safe for outdoors, but monitor for mild throat or eye irritation.",
        athletes = "Good for outdoor workouts; lower intensity slightly if sensitive.",
        workers = "Normal outdoor work conditions; maintain good hydration."
      )
    )
  } else if (category == "Unhealthy for Sensitive Groups") {
    list(
      mask = "Surgical mask or KN95 for sensitive individuals outdoors",
      purifier = "HEPA air purifier recommended indoors",
      windows = "Keep windows closed during midday peak pollution",
      exertionLimit = "Limit prolonged or heavy outdoor exertion",
      actionChecklist = list(
        "Sensitive individuals should wear a protective mask outdoors",
        "Run indoor HEPA air purifiers on medium speed",
        "Keep quick-relief inhalers and medications readily accessible",
        "Avoid strenuous exercise along busy roadways or industrial zones"
      ),
      groupAdvice = list(
        general = "Unlikely to affect the general public, but limit unnecessary prolonged exposure.",
        sensitive = "Limit outdoor exposure; move intense exercise indoors.",
        children_elderly = "Reduce prolonged outdoor playtime and outdoor physical activity.",
        athletes = "Shift intense cardio workouts to indoor facilities or early morning.",
        workers = "Take regular indoor rest breaks away from traffic zones."
      )
    )
  } else if (category == "Unhealthy") {
    list(
      mask = "N95 / KN95 Respirator strongly recommended",
      purifier = "HEPA purifier active on High speed continuous mode",
      windows = "Keep windows firmly closed",
      exertionLimit = "Avoid heavy outdoor exertion",
      actionChecklist = list(
        "Wear a tightly sealed N95 or KN95 mask whenever stepping outdoors",
        "Keep windows and doors sealed; run indoor HEPA air purifiers continuously",
        "Avoid running, cycling, or heavy exertion outside",
        "Rinse eyes and mouth with clean water after returning indoors",
        "Increase intake of antioxidant-rich foods and warm fluids"
      ),
      groupAdvice = list(
        general = "Everyone may begin to experience health effects. Cut back outdoor time.",
        sensitive = "Avoid all outdoor physical activity; stay inside an air-purified room.",
        children_elderly = "Keep children indoors; cancel outdoor playground activities.",
        athletes = "Do not exercise outdoors; substitute with indoor workouts.",
        workers = "Wear certified N95 respirators at all times during outdoor shifts."
      )
    )
  } else if (category == "Very Unhealthy") {
    list(
      mask = "N95 / FFP2 / KN95 Mask mandatory for all outdoor movement",
      purifier = "Multi-stage HEPA filter running continuously at Max CADR",
      windows = "Strictly closed and sealed",
      exertionLimit = "Avoid all outdoor physical exertion",
      actionChecklist = list(
        "Remain indoors as much as possible with sealed windows",
        "Ensure N95 mask forms a complete tight seal over nose and chin outside",
        "Operate air purifiers at maximum speed in living areas and bedrooms",
        "Use saline nasal spray to flush out trapped particulate matter",
        "Consult medical help immediately if experiencing chest tightness or wheezing"
      ),
      groupAdvice = list(
        general = "Health alert: entire population affected. Avoid non-essential outdoor trips.",
        sensitive = "Strict isolation in air-purified indoor environments.",
        children_elderly = "Keep strictly indoors with doors and windows closed.",
        athletes = "Cancel all outdoor sports, marathon training, and athletic events.",
        workers = "Mandatory high-grade respiratory protection & frequent indoor breaks."
      )
    )
  } else {
    # Hazardous
    list(
      mask = "N95 / FFP3 / Elastomeric Respirator mandatory",
      purifier = "High-CADR HEPA purifier active 24/7",
      windows = "Strictly sealed with draft stoppers",
      exertionLimit = "Prohibited — Emergency Health Warning",
      actionChecklist = list(
        "EMERGENCY HEALTH HAZARD — Stay strictly indoors",
        "Do NOT open windows or doors under any circumstances",
        "Wear sealed N95/FFP3 masks even for brief movement outside",
        "Establish a clean-air room inside your home using HEPA filtration",
        "Keep emergency healthcare phone numbers accessible"
      ),
      groupAdvice = list(
        general = "Emergency conditions: serious risk for the entire population.",
        sensitive = "Urgent: stay in air-purified clean room; seek emergency medical care if in distress.",
        children_elderly = "Absolute indoor lockdown recommended.",
        athletes = "All physical training must be strictly indoors in filtered air.",
        workers = "Halt non-essential outdoor work immediately."
      )
    )
  }
}

#' Load the health mapping table from CSV, if available.
load_health_data <- function(path = "health_data.csv") {
  actual_path <- resolve_path(path)
  if (file.exists(actual_path)) {
    readr::read_csv(actual_path, show_col_types = FALSE)
  } else {
    NULL
  }
}

#' Get specific medical diseases and risk severities associated with an AQI category.
#'
#' @param category AQI category string.
#' @return A list of disease risk objects.
get_disease_risks <- function(category) {
  if (category == "Good") {
    list(
      list(name = "Asthma / COPD Flare-up", risk = "Low", description = "Air quality poses virtually no trigger risk for respiratory conditions."),
      list(name = "Allergic Rhinitis / Sinusitis", risk = "Low", description = "Low particulate load; minimal nasal and throat irritation."),
      list(name = "Cardiovascular Stress", risk = "Low", description = "Zero atmospheric stress on heart rate or blood pressure.")
    )
  } else if (category == "Moderate") {
    list(
      list(name = "Mild Allergic Rhinitis", risk = "Moderate", description = "Sensitive individuals may experience sneezing, runny nose, or throat tickle."),
      list(name = "Asthma Trigger Risk", risk = "Moderate", description = "Minor chance of respiratory discomfort during prolonged outdoor exertion."),
      list(name = "Eye & Nasal Irritation", risk = "Moderate", description = "Particulate matter may irritate hyper-sensitive mucous membranes.")
    )
  } else if (category == "Unhealthy for Sensitive Groups") {
    list(
      list(name = "Asthma Exacerbation", risk = "High", description = "Increased incidence of wheezing, shortness of breath, and asthma attacks."),
      list(name = "Acute Bronchitis", risk = "Moderate", description = "Inflammation of bronchial lining in children, seniors, and immunocompromised."),
      list(name = "Cardiovascular Strain", risk = "Moderate", description = "Elevated blood pressure & heart workload in patients with existing heart conditions.")
    )
  } else if (category == "Unhealthy") {
    list(
      list(name = "Acute Bronchitis & Pharyngitis", risk = "High", description = "Widespread throat inflammation, dry cough, and bronchial swelling."),
      list(name = "Asthma & COPD Attacks", risk = "High", description = "Frequent bronchodilator use required; acute airway restriction."),
      list(name = "Cardiovascular Events Risk", risk = "High", description = "Increased arterial constriction and risk of ischemic heart disease aggravation.")
    )
  } else if (category == "Very Unhealthy") {
    list(
      list(name = "Chronic Obstructive Pulmonary Disease (COPD) Flare", risk = "Severe", description = "Severe breathlessness, hypoxia risk, and high hospitalization hazard."),
      list(name = "Acute Respiratory Distress (ARDS)", risk = "Severe", description = "Deep lung tissue inflammation due to high PM2.5 penetration."),
      list(name = "Ischemic Heart Strain", risk = "Severe", description = "Significantly heightened risk of arrhythmia, hypertension spike, or cardiac stress.")
    )
  } else {
    # Hazardous
    list(
      list(name = "Acute Pulmonary Edema & Toxic Hypoxia", risk = "Critical", description = "Life-threatening toxic alveolar damage and acute oxygen transport impairment."),
      list(name = "Cardiorespiratory Failure Risk", risk = "Critical", description = "Emergency medical hazard for entire population; high premature mortality risk."),
      list(name = "Severe Systemic Toxicity", risk = "Critical", description = "Systemic inflammation affecting vascular, pulmonary, and neurological functions.")
    )
  }
}

#' Get health effects & recommendations for an AQI category.
#'
#' @param category AQI category string (from category.R -> classify_aqi()).
#' @return A list with `effects`, `recommendations`, `diseases`, and `safetyAdvisor`.
get_health_info <- function(category) {
  table <- load_health_data()

  effects <- list()
  recommendations <- list()

  if (!is.null(table) && category %in% table$category) {
    rows <- dplyr::filter(table, category == !!category)
    effects <- as.list(rows$effect)
    recommendations <- as.list(rows$recommendation)
  } else if (category %in% names(DEFAULT_HEALTH_MAP)) {
    def <- DEFAULT_HEALTH_MAP[[category]]
    effects <- def$effects
    recommendations <- def$recommendations
  } else {
    effects <- list("No data available.")
    recommendations <- list("Consult local health guidance.")
  }

  safety <- get_safety_advisor(category)
  diseases <- get_disease_risks(category)

  list(
    effects = effects,
    recommendations = recommendations,
    diseases = diseases,
    safetyAdvisor = safety
  )
}

# Quick manual test: Rscript disease_mapping.R
if (sys.nframe() == 0) {
  info <- get_health_info("Unhealthy")
  print(info)
}

