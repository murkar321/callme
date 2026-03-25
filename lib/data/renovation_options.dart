class RenovationOption {
  final String name;
  final String price;

  RenovationOption({required this.name, required this.price});
}

Map<String, List<RenovationOption>> renovationOptions = {

  "basic": [
    RenovationOption(name: "Cracks & Plaster Work", price: "₹2000"),
    RenovationOption(name: "Basic Wall Painting", price: "₹3000"),
    RenovationOption(name: "Minor Crack Repair", price: "₹1500"),
    RenovationOption(name: "Basic Plumbing Repair", price: "₹2500"),
    RenovationOption(name: "Basic Electrical Repair", price: "₹2500"),
    RenovationOption(name: "Simple Bathroom Repair", price: "₹4000"),
  ],

  "standard": [
    RenovationOption(name: "Full Interior Painting + Putty", price: "₹8000"),
    RenovationOption(name: "Tiles Replacement", price: "₹10000"),
    RenovationOption(name: "Bathroom Renovation", price: "₹15000"),
    RenovationOption(name: "Electrical Wiring Upgrade", price: "₹7000"),
    RenovationOption(name: "Plumbing Replacement", price: "₹8000"),
  ],

  "premium": [
    RenovationOption(name: "Designer Wall Finish", price: "₹15000"),
    RenovationOption(name: "Full Flooring", price: "₹20000"),
    RenovationOption(name: "Modular Kitchen", price: "₹50000"),
    RenovationOption(name: "False Ceiling", price: "₹18000"),
    RenovationOption(name: "Complete Electrical & Plumbing", price: "₹25000"),
    RenovationOption(name: "Waterproofing", price: "₹12000"),
  ],
};