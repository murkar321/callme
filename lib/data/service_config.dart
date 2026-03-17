class ServiceConfig {
  final String type;
  final String businessLabel;
  final List<String> services;
  final bool hasHomeVisit;

  ServiceConfig({
    required this.type,
    required this.businessLabel,
    required this.services,
    this.hasHomeVisit = false,
  });
}

final Map<String, ServiceConfig> serviceConfigs = {
  "plumber": ServiceConfig(
    type: "plumber",
    businessLabel: "Business Name",
    services: ["Pipe Repair", "Leak Fix", "Drain Cleaning"],
    hasHomeVisit: true,
  ),

  "salon": ServiceConfig(
    type: "salon",
    businessLabel: "Salon Name",
    services: ["Hair Cut", "Facial", "Makeup"],
    hasHomeVisit: true,
  ),

  "laundry": ServiceConfig(
    type: "laundry",
    businessLabel: "Shop Name",
    services: ["Shirts", "Saree", "Curtains", "Shoes"],
    hasHomeVisit: false,
  ),
};