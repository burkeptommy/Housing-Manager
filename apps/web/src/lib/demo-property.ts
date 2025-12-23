// Demo property configuration - 38 Bedford Rd, Greenwich, CT
export const demoProperty = {
  address: {
    street: '38 Bedford Rd',
    city: 'Greenwich',
    state: 'CT',
    zip: '06831',
    full: '38 Bedford Rd, Greenwich, CT 06831',
  },
  name: 'Inspiration Farm',
  details: {
    bedrooms: 4,
    bathrooms: 5.5,
    squareFeet: 4500,
    lotSize: '4.38 acres',
    yearBuilt: 1920,
    style: 'Colonial',
    stories: 2,
  },
  features: [
    'Pool',
    'Horse barn',
    'GRTA trail access',
    'Generator',
    'Security system',
    'Irrigation system',
    'Invisible fence',
    'Wine cellar',
    'Home office',
    'Mudroom',
  ],
  systems: [
    { name: 'HVAC', type: 'Carrier Central Air', installed: '2019', lastService: '2024-03-15' },
    { name: 'Water Heater', type: 'Rheem 50 Gallon', installed: '2021', lastService: '2024-01-10' },
    { name: 'Well Pump', type: 'Grundfos', installed: '2018', lastService: '2024-06-01' },
    { name: 'Septic', type: '1500 Gallon', installed: '2015', lastService: '2024-02-20' },
    { name: 'Generator', type: 'Generac 22kW', installed: '2020', lastService: '2024-04-15' },
    { name: 'Security', type: 'ADT Smart Home', installed: '2022', lastService: '2024-05-01' },
    { name: 'Pool', type: 'Gunite, Salt Water', installed: '2010', lastService: '2024-05-15' },
    { name: 'Irrigation', type: 'Rain Bird', installed: '2019', lastService: '2024-04-01' },
  ],
  images: [
    'https://photos.zillowstatic.com/fp/1d1c3e9a0e6b9c1d5c8b0e9a0e6b9c1d-cc_ft_768.webp',
    'https://photos.zillowstatic.com/fp/2e2d4f0b1f7c0d2e6d9c1f0b1f7c0d2e-cc_ft_768.webp',
    'https://photos.zillowstatic.com/fp/3f3e5g1c2g8d1e3f7e0d2g1c2g8d1e3f-cc_ft_768.webp',
  ],
  accessNotes: {
    gateCode: '1234#',
    alarmCode: '5678',
    wifiNetwork: 'InspirationFarm_5G',
    wifiPassword: 'Welcome2024!',
    lockboxLocation: 'Back door, under mat',
    emergencyShutoffs: {
      water: 'Basement, northeast corner',
      gas: 'Exterior, south side of house',
      electrical: 'Basement, main panel by stairs',
    },
  },
};

export type DemoProperty = typeof demoProperty;
