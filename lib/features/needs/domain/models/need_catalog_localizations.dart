class NeedCatalogLocalizations {
  NeedCatalogLocalizations._();

  static const categoryNames = <String, Map<String, String>>{
    'construction_building': {
      'rw': 'Ubwubatsi n\'inyubako',
      'fr': 'Construction et bâtiment',
      'sw': 'Ujenzi na majengo',
      'ar': 'الإنشاءات والبناء',
    },
    'agriculture_agribusiness': {
      'rw': 'Ubuhinzi',
      'fr': 'Agriculture',
      'sw': 'Kilimo',
      'ar': 'الزراعة',
    },
    'technology_digital': {
      'rw': 'Ikoranabuhanga n\'ibikorwa by\'ikoranabuhanga',
      'fr': 'Technologie et numérique',
      'sw': 'Teknolojia na huduma za kidijitali',
      'ar': 'التكنولوجيا والخدمات الرقمية',
    },
    'events_production': {
      'rw': 'Ibirori n\'Iminsi Mikuru',
      'fr': 'Événements et célébrations',
      'sw': 'Matukio na Sherehe',
      'ar': 'الفعاليات والاحتفالات',
    },
    'energy_utilities': {
      'rw': 'Ingufu n\'Amazi',
      'fr': 'Énergie et eau',
      'sw': 'Nishati na Maji',
      'ar': 'الطاقة والمياه',
    },
    'machinery_equipment': {
      'rw': 'Imashini n\'ibikoresho',
      'fr': 'Machines et équipements',
      'sw': 'Mashine na vifaa',
      'ar': 'الآلات والمعدات',
    },
    'professional_services': {
      'rw': 'Ubucuruzi n\'Inzobere',
      'fr': 'Affaires et services professionnels',
      'sw': 'Biashara na Huduma za Kitaalamu',
      'ar': 'الأعمال والخدمات المهنية',
    },
    'transport_logistics': {
      'rw': 'Ubwikorezi n\'ibikorwa byo gutwara ibintu',
      'fr': 'Transport et logistique',
      'sw': 'Usafiri na ugavi',
      'ar': 'النقل والخدمات اللوجستية',
    },
    'specialized_products': {
      'rw': 'Kugura no Gutangwa kw\'Ibicuruzwa',
      'fr': 'Approvisionnement et sourcing',
      'sw': 'Ununuzi na Ugavi wa Bidhaa',
      'ar': 'المشتريات والتوريد',
    },
    'education_training': {
      'rw': 'Uburezi n\'amahugurwa',
      'fr': 'Éducation et formation',
      'sw': 'Elimu na mafunzo',
      'ar': 'التعليم والتدريب',
    },
    'travel_international': {
      'rw': 'Ingendo n\'ububanyi n\'amahanga',
      'fr': 'Voyages et international',
      'sw': 'Usafiri na huduma za kimataifa',
      'ar': 'السفر والخدمات الدولية',
    },
    // New top-level categories
    'marketing_promotion': {
      'rw': 'Pazamariya n\'Gutangaza',
      'fr': 'Marketing et promotion',
      'sw': 'Masoko na Utangazaji',
      'ar': 'التسويق والترويج',
    },
    'photo_video_music_talent': {
      'rw': 'Ifoto, Amashusho, Umuziki n\'Ibibuga',
      'fr': 'Photo, vidéo, musique et talents',
      'sw': 'Picha, Video, Muziki na Vipaji',
      'ar': 'التصوير والفيديو والموسيقى والمواهب',
    },
    'beauty_fashion_styling': {
      'rw': 'Ubwiza, Imyambaro n\'Usitayire',
      'fr': 'Beauté, mode et stylisme',
      'sw': 'Urembo, Mitindo na Usafi wa Mavazi',
      'ar': 'الجمال والأزياء والتصفيف',
    },
    // Legacy slugs kept for backward-compatibility
    'music_video': {
      'rw': 'Umuziki na amashusho',
      'fr': 'Musique et vidéo',
      'sw': 'Muziki na video',
      'ar': 'الموسيقى والفيديو',
    },
    'weddings_celebrations': {
      'rw': 'Ubukwe n\'ibirori',
      'fr': 'Mariages et célébrations',
      'sw': 'Harusi na sherehe',
      'ar': 'حفلات الزفاف والاحتفالات',
    },
    'financial_services': {
      'rw': 'Serivisi z\'imari',
      'fr': 'Services financiers',
      'sw': 'Huduma za kifedha',
      'ar': 'الخدمات المالية',
    },
  };

  static const categoryDescriptions = <String, Map<String, String>>{
    'machinery_equipment': {
      'rw':
          'Gukodesha cyangwa gushaka imashini ziremereye, ibikoresho by\'inganda na jenereta.',
      'fr':
          'Location ou recherche de machines lourdes, d’équipements industriels et de générateurs.',
      'sw':
          'Kukodisha au kutafuta mashine nzito, vifaa vya viwandani na jenereta.',
      'ar': 'استئجار أو توفير الآلات الثقيلة والمعدات الصناعية والمولدات.',
    },
    'professional_services': {
      'rw':
          'Shaka abanyamategeko, abacungamari, abajyanama, ba injeniyeri n\'abanyamwuga mu bucuruzi.',
      'fr':
          'Trouvez des juristes, comptables, consultants, ingénieurs et professionnels des affaires.',
      'sw':
          'Pata wanasheria, wahasibu, washauri, wahandisi na wataalamu wa biashara.',
      'ar': 'اعثر على محامين ومحاسبين ومستشارين ومهندسين ومتخصصين في الأعمال.',
    },
    'transport_logistics': {
      'rw':
          'Ubwikorezi bw\'imizigo iremereye, amakarito, ubutumwa, kwimura no kugeza ibintu byinshi.',
      'fr':
          'Transport de marchandises lourdes, fret, courrier, déménagement et livraisons en vrac.',
      'sw':
          'Usafirishaji wa mizigo mizito, vifurushi, barua, kuhama na usambazaji wa jumla.',
      'ar': 'نقل الشحنات الثقيلة والبضائع والبريد والأثاث والتوصيلات بالجملة.',
    },
    'specialized_products': {
      'rw':
          'Kugura byinshi, ibicuruzwa bitumizwa mu mahanga, ibice by\'inganda n\'ibintu bigoye kubona.',
      'fr':
          'Achats en gros, produits importés, pièces industrielles et articles difficiles à trouver.',
      'sw':
          'Ununuzi wa jumla, bidhaa zinazoagizwa, vipuri vya viwandani na bidhaa adimu.',
      'ar':
          'المشتريات بالجملة والسلع المستوردة وقطع المصانع والمواد صعبة التوفير.',
    },
    'construction_building': {
      'rw':
          'Abubatsi, ibikoresho, ibisenge, amazi, amashanyarazi n\'imirimo y\'ubwubatsi.',
      'fr':
          'Entrepreneurs, matériaux, toiture, plomberie, électricité et travaux de génie civil.',
      'sw': 'Wakandarasi, vifaa, paa, mabomba, umeme na kazi za ujenzi.',
      'ar': 'مقاولون ومواد وأسقف وسباكة وكهرباء وأعمال مدنية.',
    },
    'agriculture_agribusiness': {
      'rw':
          'Imashini z\'ubuhinzi, imbuto, amatungo, kuhira no kugura umusaruro.',
      'fr':
          'Machines agricoles, semences, élevage, irrigation et acheteurs de récoltes.',
      'sw':
          'Mashine za kilimo, mbegu, mifugo, umwagiliaji na wanunuzi wa mazao.',
      'ar': 'الآلات الزراعية والبذور والماشية والري ومشترو المحاصيل.',
    },
    'technology_digital': {
      'rw':
          'Porogaramu, imbuga za interineti, porogaramu za telefoni, ubufasha bwa IT, imiyoboro no kwamamaza kuri interineti.',
      'fr':
          'Logiciels, sites web, applications mobiles, assistance informatique, réseaux et marketing numérique.',
      'sw':
          'Programu, tovuti, programu za simu, usaidizi wa TEHAMA, mitandao na uuzaji wa kidijitali.',
      'ar':
          'البرمجيات والمواقع وتطبيقات الهاتف ودعم تقنية المعلومات والشبكات والتسويق الرقمي.',
    },
    'events_production': {
      'rw':
          'Gutegura ibirori, amahema, amajwi, amatara, gufotora, amafunguro n\'abayobora ibirori.',
      'fr':
          'Organisation d’événements, tentes, son, éclairage, photographie, restauration et animation.',
      'sw':
          'Mipango ya matukio, mahema, sauti, taa, upigaji picha, upishi na watangazaji.',
      'ar':
          'تنظيم الفعاليات والخيام والصوت والإضاءة والتصوير والتموين ومقدمو الفعاليات.',
    },
    'energy_utilities': {
      'rw':
          'Imirasire y\'izuba, jenereta, bateri, gushyiraho amashanyarazi na sisitemu z\'amazi.',
      'fr':
          'Systèmes solaires, générateurs, batteries, installations électriques et systèmes d’eau.',
      'sw':
          'Mifumo ya sola, jenereta, betri, ufungaji wa umeme na mifumo ya maji.',
      'ar':
          'أنظمة الطاقة الشمسية والمولدات والبطاريات والتركيبات الكهربائية وأنظمة المياه.',
    },
    'education_training': {
      'rw':
          'Uburezi, kwimenyereza umwuga, amahugurwa, kwinjira mu mashuri, ubufasha mu masomo no guteza imbere ubumenyi.',
      'fr':
          'Éducation, stages, formation professionnelle, admissions, soutien scolaire et développement des compétences.',
      'sw':
          'Elimu, mafunzo kwa vitendo, mafunzo ya kazi, udahili, msaada wa masomo na ukuzaji wa ujuzi.',
      'ar': 'التعليم والتدريب المهني والقبول والدعم الأكاديمي وتنمية المهارات.',
    },
    'travel_international': {
      'rw':
          'Visa, amatike y\'indege, Hajj na Umrah, amacumbi, kwiga mu mahanga no kwimuka mu bindi bihugu.',
      'fr':
          'Visas, billets d’avion, Hajj et Omra, hébergement, études à l’étranger et déménagement international.',
      'sw':
          'Visa, tiketi za ndege, Hija na Umra, malazi, masomo nje ya nchi na kuhamia kimataifa.',
      'ar':
          'التأشيرات وتذاكر الطيران والحج والعمرة والإقامة والدراسة بالخارج والانتقال الدولي.',
    },
    'music_video': {
      'rw': 'Abahanzi n\'abakozi b\'umusaruro w\'umuziki, filimi n\'amashusho.',
      'fr':
          'Artistes et professionnels de la production musicale, cinématographique et vidéo.',
      'sw': 'Wasanii na wataalamu wa utayarishaji wa muziki, filamu na video.',
      'ar': 'فنانون ومتخصصون في إنتاج الموسيقى والأفلام والفيديو.',
    },
    'weddings_celebrations': {
      'rw':
          'Serivisi zo guhanga no gutegura amashuri asoza, ubukwe n\'ibirori by\'imiryango.',
      'fr':
          'Services créatifs et événementiels pour les remises de diplômes, mariages et fêtes.',
      'sw':
          'Huduma za ubunifu na matukio ya mahafali, harusi na sherehe za kijamii.',
      'ar':
          'خدمات إبداعية وتنظيمية لحفلات التخرج والزفاف والمناسبات الاجتماعية.',
    },
    'financial_services': {
      'rw':
          'Inguzanyo, kuvunja amafaranga, abakozi ba banki, SACCO, microfinance n\'inama z\'imari.',
      'fr':
          'Prêts, change, agents bancaires, SACCO, microfinance et conseil financier.',
      'sw':
          'Mikopo, ubadilishaji fedha, mawakala wa benki, SACCO, huduma ndogo za kifedha na ushauri.',
      'ar':
          'القروض وصرف العملات ووكلاء البنوك والتعاونيات والتمويل الأصغر والاستشارات المالية.',
    },
    'marketing_promotion': {
      'rw':
          'Kwamamaza kuri interineti, ku mbuga nkoranyambaga, kwamamaza ibicuruzwa no gutangaza brand.',
      'fr':
          'Marketing numérique, réseaux sociaux, publicité, influenceurs et promotion de marque.',
      'sw':
          'Masoko ya kidijitali, mitandao ya kijamii, matangazo, washawishi na utangazaji wa chapa.',
      'ar':
          'التسويق الرقمي ووسائل التواصل الاجتماعي والإعلانات والمؤثرين والترويج للعلامة التجارية.',
    },
    'photo_video_music_talent': {
      'rw':
          'Gufotora, gukorora amashusho, umuziki, DJ, abakinnyi n\'abafite ibibuga by\'ubuhanzi.',
      'fr':
          'Photographie, vidéographie, production musicale, DJ, artistes et talents créatifs.',
      'sw':
          'Upigaji picha, utengenezaji video, muziki, DJ, wanamuziki na wasanii wa ubunifu.',
      'ar':
          'التصوير الفوتوغرافي والفيديو وإنتاج الموسيقى والـDJ والفنانين والمواهب الإبداعية.',
    },
    'beauty_fashion_styling': {
      'rw':
          'Gusana umusatsi, gutwika, gusona imyenda, gushushanya imyambaro no gutegura isura.',
      'fr':
          'Coiffure, maquillage, couture, création de mode et stylisme personnel.',
      'sw':
          'Kutengeneza nywele, makeup, ushonaji, ubunifu wa mitindo na ushauri wa mavazi.',
      'ar':
          'تصفيف الشعر والمكياج والخياطة وتصميم الأزياء والتصفيف الشخصي.',
    },
  };

  static const capabilityNames = <String, Map<String, String>>{
    'social_media_marketing': {
      'rw': 'Kwamamaza ku mbuga nkoranyambaga',
    },
    'tiktok_promotion': {
      'rw': 'Kwamamaza kuri TikTok',
    },
    'instagram_promotion': {
      'rw': 'Kwamamaza kuri Instagram',
    },
    'youtube_promotion': {
      'rw': 'Kwamamaza kuri YouTube',
    },
    'facebook_promotion': {
      'rw': 'Kwamamaza kuri Facebook',
    },
    'influencer_marketing': {
      'rw': 'Kwamamaza hifashishijwe abantu bakurikirwa',
    },
    'content_creation': {
      'rw': 'Gukora ibikubiye mu itangazamakuru',
    },
    'product_reviews': {
      'rw': 'Isuzuma ry\'ibicuruzwa',
    },
    'event_promotion': {
      'rw': 'Kwamamaza ibirori',
    },
    'whatsapp_community_promotion': {
      'rw': 'Kwamamaza kuri WhatsApp no mu matsinda',
    },
    'affiliate_marketing': {
      'rw': 'Kwamamaza hakoreshejwe abafatanyabikorwa',
    },
    'advertising_campaigns': {
      'rw': 'Ubukangurambaga bwo kwamamaza',
    },
    'brand_promotion': {
      'rw': 'Kwamamaza ikirango',
    },
    'other_marketing_services': {
      'rw': 'Izindi serivisi zo kwamamaza',
    },
    'i_have_an_audience': {
      'rw': 'Mfite abantu bankurikira',
    },
    'excavator_hire': {
      'rw': 'Gukodesha imashini zicukura',
      'fr': 'Location de pelles mécaniques',
      'sw': 'Kukodisha ekskaveta',
      'ar': 'تأجير الحفارات',
    },
    'tractor_hire': {
      'rw': 'Gukodesha za trakitari',
      'fr': 'Location de tracteurs',
      'sw': 'Kukodisha matrekta',
      'ar': 'تأجير الجرارات',
    },
    'crane_hire': {
      'rw': 'Gukodesha za krani',
      'fr': 'Location de grues',
      'sw': 'Kukodisha kreni',
      'ar': 'تأجير الرافعات',
    },
    'loader_hire': {
      'rw': 'Gukodesha imashini zipakira',
      'fr': 'Location de chargeuses',
      'sw': 'Kukodisha vipakiaji',
      'ar': 'تأجير اللوادر',
    },
    'grader_hire': {
      'rw': 'Gukodesha imashini ziringaniza ubutaka',
      'fr': 'Location de niveleuses',
      'sw': 'Kukodisha mashine za kusawazisha',
      'ar': 'تأجير ممهدات الطرق',
    },
    'generator_hire': {
      'rw': 'Gukodesha za jenereta',
      'fr': 'Location de générateurs',
      'sw': 'Kukodisha jenereta',
      'ar': 'تأجير المولدات',
    },
    'agricultural_equipment': {
      'rw': 'Ibikoresho by\'ubuhinzi',
      'fr': 'Équipements agricoles',
      'sw': 'Vifaa vya kilimo',
      'ar': 'المعدات الزراعية',
    },
    'industrial_equipment': {
      'rw': 'Ibikoresho by\'inganda',
      'fr': 'Équipements industriels',
      'sw': 'Vifaa vya viwandani',
      'ar': 'المعدات الصناعية',
    },
    'other_machinery': {
      'rw': 'Izindi mashini',
      'fr': 'Autres machines',
      'sw': 'Mashine nyingine',
      'ar': 'آلات أخرى',
    },
    'company_registration': {
      'rw': 'Kwiyandikisha kw\'ikigo',
      'fr': 'Immatriculation d’entreprise',
      'sw': 'Usajili wa kampuni',
      'ar': 'تسجيل الشركات',
    },
    'legal_services': {
      'rw': 'Serivisi z\'amategeko',
      'fr': 'Services juridiques',
      'sw': 'Huduma za kisheria',
      'ar': 'الخدمات القانونية',
    },
    'accounting_tax': {
      'rw': 'Ibaruramari n\'imisoro',
      'fr': 'Comptabilité et fiscalité',
      'sw': 'Uhasibu na kodi',
      'ar': 'المحاسبة والضرائب',
    },
    'business_consulting': {
      'rw': 'Kugira inama ku bucuruzi',
      'fr': 'Conseil aux entreprises',
      'sw': 'Ushauri wa biashara',
      'ar': 'استشارات الأعمال',
    },
    'hr_services': {
      'rw': 'Serivisi z\'abakozi',
      'fr': 'Services des ressources humaines',
      'sw': 'Huduma za rasilimali watu',
      'ar': 'خدمات الموارد البشرية',
    },
    'engineering_consulting': {
      'rw': 'Inama z\'ubwubatsi n\'ubuhanga',
      'fr': 'Conseil en ingénierie',
      'sw': 'Ushauri wa uhandisi',
      'ar': 'استشارات هندسية',
    },
    'architecture_services': {
      'rw': 'Serivisi z\'ubwubatsi',
      'fr': 'Services d’architecture',
      'sw': 'Huduma za usanifu majengo',
      'ar': 'خدمات الهندسة المعمارية',
    },
    'other_professional': {
      'rw': 'Izindi serivisi z\'umwuga',
      'fr': 'Autres services professionnels',
      'sw': 'Huduma nyingine za kitaalamu',
      'ar': 'خدمات مهنية أخرى',
    },
    'heavy_haulage': {
      'rw': 'Gutwara imizigo iremereye',
      'fr': 'Transport de charges lourdes',
      'sw': 'Usafirishaji wa mizigo mizito',
      'ar': 'نقل الحمولات الثقيلة',
    },
    'truck_hire': {
      'rw': 'Gukodesha amakamyo',
      'fr': 'Location de camions',
      'sw': 'Kukodisha malori',
      'ar': 'تأجير الشاحنات',
    },
    'cargo_transport': {
      'rw': 'Gutwara imizigo',
      'fr': 'Transport de marchandises',
      'sw': 'Usafirishaji wa mizigo',
      'ar': 'نقل البضائع',
    },
    'courier_delivery': {
      'rw': 'Kohereza ubutumwa bwihuse',
      'fr': 'Courrier et livraison express',
      'sw': 'Ujumbe na uwasilishaji wa haraka',
      'ar': 'البريد والتوصيل السريع',
    },
    'moving_services': {
      'rw': 'Serivisi zo kwimura ibintu',
      'fr': 'Services de déménagement',
      'sw': 'Huduma za kuhama',
      'ar': 'خدمات نقل الأثاث',
    },
    'vehicle_transport': {
      'rw': 'Gutwara ibinyabiziga',
      'fr': 'Transport de véhicules',
      'sw': 'Usafirishaji wa magari',
      'ar': 'نقل المركبات',
    },
    'bulk_delivery': {
      'rw': 'Kugeza ibintu byinshi',
      'fr': 'Livraison en vrac',
      'sw': 'Uwasilishaji wa bidhaa nyingi',
      'ar': 'التوصيل بالجملة',
    },
    'other_logistics': {
      'rw': 'Izindi serivisi z\'ubwikorezi',
      'fr': 'Autres services logistiques',
      'sw': 'Huduma nyingine za ugavi',
      'ar': 'خدمات لوجستية أخرى',
    },
    'cold_chain_transport': {
      'rw': 'Ubwikorezi bukonjesha ibicuruzwa',
      'fr': 'Transport sous chaîne du froid',
      'sw': 'Usafirishaji wa bidhaa za ubaridi',
      'ar': 'النقل المبرد',
    },
    'bulk_procurement': {
      'rw': 'Kugura ibikoresho byinshi',
      'fr': 'Approvisionnement en gros',
      'sw': 'Ununuzi wa jumla',
      'ar': 'التوريد بالجملة',
    },
    'imported_products': {
      'rw': 'Ibicuruzwa bitumizwa mu mahanga',
      'fr': 'Produits importés',
      'sw': 'Bidhaa zinazoagizwa kutoka nje',
      'ar': 'المنتجات المستوردة',
    },
    'industrial_parts': {
      'rw': 'Ibice by\'imashini z\'inganda',
      'fr': 'Pièces industrielles',
      'sw': 'Vipuri vya viwandani',
      'ar': 'قطع صناعية',
    },
    'spare_parts': {
      'rw': 'Ibice bisimbura ibyashaje',
      'fr': 'Pièces de rechange',
      'sw': 'Vipuri',
      'ar': 'قطع الغيار',
    },
    'electronics_procurement': {
      'rw': 'Kugura ibikoresho by\'ikoranabuhanga',
      'fr': 'Approvisionnement en électronique',
      'sw': 'Ununuzi wa vifaa vya kielektroniki',
      'ar': 'توريد الأجهزة الإلكترونية',
    },
    'hard_to_find_products': {
      'rw': 'Ibicuruzwa bigoye kubona',
      'fr': 'Produits difficiles à trouver',
      'sw': 'Bidhaa ambazo ni vigumu kupata',
      'ar': 'منتجات يصعب العثور عليها',
    },
    'equipment_sourcing': {
      'rw': 'Gushaka ibikoresho',
      'fr': 'Recherche d’équipements',
      'sw': 'Upatikanaji wa vifaa',
      'ar': 'توفير المعدات',
    },
    'other_procurement': {
      'rw': 'Ubundi buryo bwo kugura ibikoresho',
      'fr': 'Autres services d’approvisionnement',
      'sw': 'Huduma nyingine za ununuzi',
      'ar': 'خدمات توريد أخرى',
    },
    'medical_supplies': {
      'rw': 'Ibikoresho by\'ubuvuzi na laboratwari',
      'fr': 'Fournitures médicales et de laboratoire',
      'sw': 'Vifaa vya afya na maabara',
      'ar': 'المستلزمات الطبية ومستلزمات المختبرات',
    },
    'electronic_hardware': {
      'rw': 'Ibikoresho n\'ibice by\'ikoranabuhanga',
      'fr': 'Électronique et composants spécialisés',
      'sw': 'Vifaa na vipuri maalum vya kielektroniki',
      'ar': 'الأجهزة والمكونات الإلكترونية المتخصصة',
    },
    'building_contractors': {
      'rw': 'Abubatsi b\'inyubako',
      'fr': 'Entrepreneurs en bâtiment',
      'sw': 'Wakandarasi wa majengo',
      'ar': 'مقاولو المباني',
    },
    'construction_materials': {
      'rw': 'Ibikoresho by\'ubwubatsi',
      'fr': 'Matériaux de construction',
      'sw': 'Vifaa vya ujenzi',
      'ar': 'مواد البناء',
    },
    'roofing_services': {
      'rw': 'Serivisi zo gusakara',
      'fr': 'Services de toiture',
      'sw': 'Huduma za kuezeka',
      'ar': 'خدمات الأسقف',
    },
    'plumbing_services': {
      'rw': 'Serivisi z\'imiyoboro y\'amazi',
      'fr': 'Plomberie',
      'sw': 'Huduma za mabomba',
      'ar': 'خدمات السباكة',
    },
    'electrical_works': {
      'rw': 'Imirimo y\'amashanyarazi',
      'fr': 'Travaux électriques',
      'sw': 'Kazi za umeme',
      'ar': 'الأعمال الكهربائية',
    },
    'concrete_works': {
      'rw': 'Imirimo ya beto',
      'fr': 'Travaux de béton',
      'sw': 'Kazi za saruji',
      'ar': 'أعمال الخرسانة',
    },
    'surveying_services': {
      'rw': 'Serivisi zo gupima ubutaka',
      'fr': 'Services d’arpentage',
      'sw': 'Huduma za upimaji ardhi',
      'ar': 'خدمات المساحة',
    },
    'excavation_works': {
      'rw': 'Imirimo yo gucukura',
      'fr': 'Travaux d’excavation',
      'sw': 'Kazi za uchimbaji',
      'ar': 'أعمال الحفر',
    },
    'other_construction': {
      'rw': 'Ubundi bwubatsi',
      'fr': 'Autres travaux de construction',
      'sw': 'Huduma nyingine za ujenzi',
      'ar': 'أعمال بناء أخرى',
    },
    'farm_machinery': {
      'rw': 'Imashini z\'ubuhinzi',
      'fr': 'Machines agricoles',
      'sw': 'Mashine za kilimo',
      'ar': 'الآلات الزراعية',
    },
    'seeds_inputs': {
      'rw': 'Imbuto n\'ibikoresho by\'ubuhinzi',
      'fr': 'Semences et intrants agricoles',
      'sw': 'Mbegu na pembejeo',
      'ar': 'البذور والمدخلات الزراعية',
    },
    'livestock_sourcing': {
      'rw': 'Gushaka amatungo',
      'fr': 'Approvisionnement en bétail',
      'sw': 'Upatikanaji wa mifugo',
      'ar': 'توفير الماشية',
    },
    'irrigation_services': {
      'rw': 'Serivisi zo kuhira',
      'fr': 'Services d’irrigation',
      'sw': 'Huduma za umwagiliaji',
      'ar': 'خدمات الري',
    },
    'produce_buyers': {
      'rw': 'Abaguzi b\'umusaruro',
      'fr': 'Acheteurs de récoltes',
      'sw': 'Wanunuzi wa mazao',
      'ar': 'مشترو المحاصيل',
    },
    'farm_services': {
      'rw': 'Serivisi z\'ubuhinzi',
      'fr': 'Services agricoles',
      'sw': 'Huduma za kilimo',
      'ar': 'خدمات زراعية',
    },
    'agricultural_transport': {
      'rw': 'Ubwikorezi bw\'ibikomoka ku buhinzi',
      'fr': 'Transport agricole',
      'sw': 'Usafirishaji wa mazao ya kilimo',
      'ar': 'النقل الزراعي',
    },
    'other_agriculture': {
      'rw': 'Izindi serivisi z\'ubuhinzi',
      'fr': 'Autres services agricoles',
      'sw': 'Huduma nyingine za kilimo',
      'ar': 'خدمات زراعية أخرى',
    },
    'software_development': {
      'rw': 'Gukora porogaramu',
      'fr': 'Développement logiciel',
      'sw': 'Utengenezaji wa programu',
      'ar': 'تطوير البرمجيات',
    },
    'website_development': {
      'rw': 'Gukora imbuga za interineti',
      'fr': 'Développement de sites web',
      'sw': 'Utengenezaji wa tovuti',
      'ar': 'تطوير المواقع الإلكترونية',
    },
    'mobile_app_development': {
      'rw': 'Gukora porogaramu za telefoni',
      'fr': 'Développement d’applications mobiles',
      'sw': 'Utengenezaji wa programu za simu',
      'ar': 'تطوير تطبيقات الهاتف',
    },
    'it_support': {
      'rw': 'Ubufasha bwa IT',
      'fr': 'Assistance informatique',
      'sw': 'Usaidizi wa TEHAMA',
      'ar': 'دعم تقنية المعلومات',
    },
    'networking_services': {
      'rw': 'Serivisi z\'imiyoboro ya mudasobwa',
      'fr': 'Services réseau',
      'sw': 'Huduma za mitandao',
      'ar': 'خدمات الشبكات',
    },
    'cybersecurity_services': {
      'rw': 'Umutekano wa mudasobwa',
      'fr': 'Cybersécurité',
      'sw': 'Usalama wa mtandao',
      'ar': 'الأمن السيبراني',
    },
    'digital_marketing': {
      'rw': 'Kwamamaza kuri interineti',
      'fr': 'Marketing numérique',
      'sw': 'Uuzaji wa kidijitali',
      'ar': 'التسويق الرقمي',
    },
    'automation_services': {
      'rw': 'Serivisi zo gukoresha imashini',
      'fr': 'Services d’automatisation',
      'sw': 'Huduma za otomatiki',
      'ar': 'خدمات الأتمتة',
    },
    'other_technology': {
      'rw': 'Izindi serivisi z\'ikoranabuhanga',
      'fr': 'Autres services technologiques',
      'sw': 'Huduma nyingine za teknolojia',
      'ar': 'خدمات تقنية أخرى',
    },
    'event_planning': {
      'rw': 'Gutegura ibirori',
      'fr': 'Organisation d’événements',
      'sw': 'Mipango ya matukio',
      'ar': 'تنظيم الفعاليات',
    },
    'tent_hire': {
      'rw': 'Amahema',
      'fr': 'Tentes',
      'sw': 'Mahema',
      'ar': 'الخيام',
    },
    'sound_systems': {
      'rw': 'Ibikoresho by\'amajwi',
      'fr': 'Systèmes de sonorisation',
      'sw': 'Mifumo ya sauti',
      'ar': 'أنظمة الصوت',
    },
    'lighting_hire': {
      'rw': 'Amatara',
      'fr': 'Éclairage',
      'sw': 'Taa',
      'ar': 'الإضاءة',
    },
    'photography_services': {
      'rw': 'Gufotora',
      'fr': 'Photographie',
      'sw': 'Upigaji picha',
      'ar': 'التصوير الفوتوغرافي',
    },
    'videography_services': {
      'rw': 'Gukora amashusho',
      'fr': 'Réalisation vidéo',
      'sw': 'Utengenezaji wa video',
      'ar': 'تصوير الفيديو',
    },
    'mc_services': {
      'rw': 'Abayobora ibirori',
      'fr': 'Maîtres de cérémonie',
      'sw': 'Watangazaji wa hafla',
      'ar': 'مقدمو الفعاليات',
    },
    'catering_services': {
      'rw': 'Gutegura amafunguro',
      'fr': 'Service traiteur',
      'sw': 'Huduma za upishi',
      'ar': 'خدمات تقديم الطعام',
    },
    'event_equipment': {
      'rw': 'Ibikoresho by\'ibirori',
      'fr': 'Équipement événementiel',
      'sw': 'Vifaa vya matukio',
      'ar': 'معدات الفعاليات',
    },
    'other_events': {
      'rw': 'Ibindi bijyanye n\'ibirori',
      'fr': 'Autres services événementiels',
      'sw': 'Huduma nyingine za matukio',
      'ar': 'خدمات فعاليات أخرى',
    },
    'solar_systems': {
      'rw': 'Sisitemu z\'imirasire y\'izuba',
      'fr': 'Systèmes solaires',
      'sw': 'Mifumo ya sola',
      'ar': 'أنظمة الطاقة الشمسية',
    },
    'generator_supply': {
      'rw': 'Jenereta',
      'fr': 'Générateurs',
      'sw': 'Jenereta',
      'ar': 'المولدات',
    },
    'battery_supply': {
      'rw': 'Bateri',
      'fr': 'Batteries',
      'sw': 'Betri',
      'ar': 'البطاريات',
    },
    'electrical_installation': {
      'rw': 'Gushyiraho amashanyarazi',
      'fr': 'Installation électrique',
      'sw': 'Ufungaji wa umeme',
      'ar': 'التركيبات الكهربائية',
    },
    'water_systems': {
      'rw': 'Sisitemu z\'amazi',
      'fr': 'Systèmes d’eau',
      'sw': 'Mifumo ya maji',
      'ar': 'أنظمة المياه',
    },
    'borehole_drilling': {
      'rw': 'Gucukura amariba maremare',
      'fr': 'Forage de puits',
      'sw': 'Uchimbaji wa visima virefu',
      'ar': 'حفر الآبار',
    },
    'backup_power': {
      'rw': 'Amashanyarazi y\'inyongera',
      'fr': 'Alimentation électrique de secours',
      'sw': 'Umeme wa akiba',
      'ar': 'طاقة احتياطية',
    },
    'energy_consulting': {
      'rw': 'Inama ku bijyanye n\'ingufu',
      'fr': 'Conseil en énergie',
      'sw': 'Ushauri wa nishati',
      'ar': 'استشارات الطاقة',
    },
    'other_energy': {
      'rw': 'Izindi serivisi z\'ingufu',
      'fr': 'Autres services énergétiques',
      'sw': 'Huduma nyingine za nishati',
      'ar': 'خدمات طاقة أخرى',
    },
    'visa_assistance': {
      'rw': 'Ubufasha mu kubona visa',
      'fr': 'Assistance pour les visas',
      'sw': 'Msaada wa visa',
      'ar': 'المساعدة في التأشيرات',
    },
    'flight_tickets': {
      'rw': 'Amatike y\'indege',
      'fr': 'Billets d’avion',
      'sw': 'Tiketi za ndege',
      'ar': 'تذاكر الطيران',
    },
    'travel_packages': {
      'rw': 'Ingendo zateguwe',
      'fr': 'Forfaits de voyage',
      'sw': 'Vifurushi vya safari',
      'ar': 'باقات السفر',
    },
    'accommodation': {
      'rw': 'Amacumbi',
      'fr': 'Hébergement',
      'sw': 'Malazi',
      'ar': 'الإقامة',
    },
    'airport_transfers': {
      'rw': 'Ubwikorezi bwo ku kibuga cy\'indege',
      'fr': 'Transferts aéroport',
      'sw': 'Usafiri wa uwanja wa ndege',
      'ar': 'النقل من وإلى المطار',
    },
    'travel_documentation': {
      'rw': 'Inyandiko z\'ingendo',
      'fr': 'Documents de voyage',
      'sw': 'Nyaraka za usafiri',
      'ar': 'وثائق السفر',
    },
    'other_travel': {
      'rw': 'Izindi serivisi z\'ingendo',
      'fr': 'Autres services de voyage',
      'sw': 'Huduma nyingine za usafiri',
      'ar': 'خدمات سفر أخرى',
    },
    'internship_placement': {
      'rw': 'Gushakirwa aho kwimenyereza umwuga',
      'fr': 'Placement en stage',
      'sw': 'Kupangiwa mafunzo kwa vitendo',
      'ar': 'التدريب العملي',
    },
    'private_tutoring': {
      'rw': 'Amasomo yigishwa ku giti cy\'umuntu',
      'fr': 'Cours particuliers',
      'sw': 'Mafunzo ya binafsi',
      'ar': 'الدروس الخصوصية',
    },
    'online_classes': {
      'rw': 'Amasomo yo kuri interineti',
      'fr': 'Cours en ligne',
      'sw': 'Madarasa ya mtandaoni',
      'ar': 'دروس عبر الإنترنت',
    },
    'professional_training': {
      'rw': 'Amahugurwa y\'umwuga',
      'fr': 'Formation professionnelle',
      'sw': 'Mafunzo ya kitaalamu',
      'ar': 'التدريب المهني',
    },
    'vocational_training': {
      'rw': 'Amahugurwa y\'imyuga',
      'fr': 'Formation professionnelle technique',
      'sw': 'Mafunzo ya ufundi',
      'ar': 'التدريب الحرفي',
    },
    'university_admissions': {
      'rw': 'Kwinjira muri kaminuza',
      'fr': 'Admissions universitaires',
      'sw': 'Udahili wa vyuo vikuu',
      'ar': 'القبول الجامعي',
    },
    'study_abroad_guidance': {
      'rw': 'Inama zo kwiga mu mahanga',
      'fr': 'Conseils pour étudier à l’étranger',
      'sw': 'Mwongozo wa masomo nje ya nchi',
      'ar': 'الإرشاد للدراسة بالخارج',
    },
    'academic_consulting': {
      'rw': 'Inama mu bijyanye n\'amasomo',
      'fr': 'Conseil académique',
      'sw': 'Ushauri wa masomo',
      'ar': 'استشارات أكاديمية',
    },
    'exam_preparation': {
      'rw': 'Kwitegura ibizamini',
      'fr': 'Préparation aux examens',
      'sw': 'Maandalizi ya mitihani',
      'ar': 'التحضير للامتحانات',
    },
    'language_training': {
      'rw': 'Amahugurwa y\'indimi',
      'fr': 'Formation linguistique',
      'sw': 'Mafunzo ya lugha',
      'ar': 'تدريب اللغات',
    },
    'computer_training': {
      'rw': 'Amahugurwa ya mudasobwa',
      'fr': 'Formation informatique',
      'sw': 'Mafunzo ya kompyuta',
      'ar': 'التدريب على الحاسوب',
    },
    'it_internships': {
      'rw': 'Imyitozo y\'akazi mu ikoranabuhanga',
      'fr': 'Stages en informatique',
      'sw': 'Mafunzo kwa vitendo ya TEHAMA',
      'ar': 'تدريب عملي في تقنية المعلومات',
    },
    'software_development_internships': {
      'rw': 'Imyitozo yo gukora porogaramu',
      'fr': 'Stages en développement logiciel',
      'sw': 'Mafunzo kwa vitendo ya utengenezaji programu',
      'ar': 'تدريب عملي على تطوير البرمجيات',
    },
    'it_support_internships': {
      'rw': 'Imyitozo mu bufasha bwa IT',
      'fr': 'Stages en assistance informatique',
      'sw': 'Mafunzo kwa vitendo ya usaidizi wa TEHAMA',
      'ar': 'تدريب عملي على دعم تقنية المعلومات',
    },
    'accounting_internships': {
      'rw': 'Imyitozo mu ibaruramari',
      'fr': 'Stages en comptabilité',
      'sw': 'Mafunzo kwa vitendo ya uhasibu',
      'ar': 'تدريب عملي في المحاسبة',
    },
    'engineering_internships': {
      'rw': 'Imyitozo mu buhanga',
      'fr': 'Stages en ingénierie',
      'sw': 'Mafunzo kwa vitendo ya uhandisi',
      'ar': 'تدريب عملي في الهندسة',
    },
    'marketing_internships': {
      'rw': 'Imyitozo mu kwamamaza',
      'fr': 'Stages en marketing',
      'sw': 'Mafunzo kwa vitendo ya uuzaji',
      'ar': 'تدريب عملي في التسويق',
    },
    'business_internships': {
      'rw': 'Imyitozo mu bucuruzi',
      'fr': 'Stages en entreprise',
      'sw': 'Mafunzo kwa vitendo ya biashara',
      'ar': 'تدريب عملي في الأعمال',
    },
    'health_nursing_placements': {
      'rw': 'Imyitozo mu buvuzi n\'ubuforomo',
      'fr': 'Stages en santé et soins infirmiers',
      'sw': 'Mafunzo kwa vitendo ya afya na uuguzi',
      'ar': 'تدريب عملي في الصحة والتمريض',
    },
    'hospitality_internships': {
      'rw': 'Imyitozo mu kwakira abantu',
      'fr': 'Stages en hôtellerie',
      'sw': 'Mafunzo kwa vitendo ya ukarimu',
      'ar': 'تدريب عملي في الضيافة',
    },
    'administrative_internships': {
      'rw': 'Imyitozo mu mirimo y\'ubuyobozi',
      'fr': 'Stages administratifs',
      'sw': 'Mafunzo kwa vitendo ya utawala',
      'ar': 'تدريب عملي إداري',
    },
    'travel_agency_services': {
      'rw': 'Serivisi z\'ibiro bishinzwe ingendo',
      'fr': 'Services d’agence de voyage',
      'sw': 'Huduma za wakala wa usafiri',
      'ar': 'خدمات وكالات السفر',
    },
    'travel_consultation': {
      'rw': 'Inama z\'ingendo',
      'fr': 'Conseil en voyage',
      'sw': 'Ushauri wa usafiri',
      'ar': 'استشارات السفر',
    },
    'hajj_umrah': {
      'rw': 'Ingendo za Hija na Umura',
      'fr': 'Voyages du Hajj et de la Omra',
      'sw': 'Safari za Hija na Umra',
      'ar': 'رحلات الحج والعمرة',
    },
    'hotel_accommodation': {
      'rw': 'Amahoteri n\'amacumbi',
      'fr': 'Hôtels et hébergement',
      'sw': 'Hoteli na malazi',
      'ar': 'الفنادق والإقامة',
    },
    'travel_insurance': {
      'rw': 'Ubwishingizi bw\'ingendo',
      'fr': 'Assurance voyage',
      'sw': 'Bima ya usafiri',
      'ar': 'تأمين السفر',
    },
    'tour_packages': {
      'rw': 'Ingendo zo gusura ahantu',
      'fr': 'Circuits touristiques',
      'sw': 'Vifurushi vya utalii',
      'ar': 'باقات سياحية',
    },
    'study_abroad': {
      'rw': 'Kwiga mu mahanga',
      'fr': 'Études à l’étranger',
      'sw': 'Masomo nje ya nchi',
      'ar': 'الدراسة بالخارج',
    },
    'international_relocation': {
      'rw': 'Kwimukira mu kindi gihugu',
      'fr': 'Déménagement international',
      'sw': 'Kuhamia nchi nyingine',
      'ar': 'الانتقال إلى الخارج',
    },
    'music_video_models': {
      'rw': 'Abakinnyi b\'amashusho y\'umuziki',
      'fr': 'Modèles de clips musicaux',
      'sw': 'Wanamitindo wa video za muziki',
      'ar': 'عارضو فيديوهات الموسيقى',
    },
    'dancers': {
      'rw': 'Ababyinnyi',
      'fr': 'Danseurs',
      'sw': 'Wachezaji',
      'ar': 'راقصون',
    },
    'actors_actresses': {
      'rw': 'Abakinnyi ba filimi',
      'fr': 'Acteurs et actrices',
      'sw': 'Waigizaji',
      'ar': 'ممثلون وممثلات',
    },
    'background_extras': {
      'rw': 'Abakinnyi bunganira',
      'fr': 'Figurants',
      'sw': 'Waigizaji wa ziada',
      'ar': 'ممثلون إضافيون',
    },
    'singers_vocalists': {
      'rw': 'Abaririmbyi',
      'fr': 'Chanteurs et vocalistes',
      'sw': 'Waimbaji',
      'ar': 'المغنون',
    },
    'songwriters': {
      'rw': 'Abanditsi b\'indirimbo',
      'fr': 'Auteurs-compositeurs',
      'sw': 'Watunzi wa nyimbo',
      'ar': 'كتّاب الأغاني',
    },
    'music_producers': {
      'rw': 'Abatunganya umuziki',
      'fr': 'Producteurs de musique',
      'sw': 'Watayarishaji wa muziki',
      'ar': 'منتجو الموسيقى',
    },
    'recording_studios': {
      'rw': 'Sitidiyo zo gufata amajwi',
      'fr': 'Studios d’enregistrement',
      'sw': 'Studio za kurekodi',
      'ar': 'استوديوهات التسجيل',
    },
    'mixing_mastering': {
      'rw': 'Kuvanga no kunoza amajwi',
      'fr': 'Mixage et matriçage',
      'sw': 'Uchanganyaji na umaliziaji wa sauti',
      'ar': 'مزج وإتقان الصوت',
    },
    'videographers': {
      'rw': 'Abafata amashusho',
      'fr': 'Vidéastes',
      'sw': 'Wapiga video',
      'ar': 'مصور فيديو',
    },
    'video_editors': {
      'rw': 'Abatunganya amashusho',
      'fr': 'Monteurs vidéo',
      'sw': 'Wahariri wa video',
      'ar': 'محررو الفيديو',
    },
    'photographers': {
      'rw': 'Abafotora',
      'fr': 'Photographes',
      'sw': 'Wapiga picha',
      'ar': 'مصورون',
    },
    'music_video_makeup': {
      'rw': 'Abogosha kandi basiga abantu',
      'fr': 'Maquilleurs',
      'sw': 'Wasanii wa vipodozi',
      'ar': 'خبراء التجميل',
    },
    'music_video_stylists': {
      'rw': 'Abatunganya imyambarire',
      'fr': 'Stylistes',
      'sw': 'Watengenezaji wa mitindo',
      'ar': 'منسقو الأزياء',
    },
    'graduation_photography': {
      'rw': 'Gufotora iminsi mikuru yo kurangiza amashuri',
      'fr': 'Photographie de remise de diplôme',
      'sw': 'Upigaji picha wa mahafali',
      'ar': 'تصوير حفلات التخرج',
    },
    'graduation_videography': {
      'rw': 'Gufata amashusho y\'iminsi mikuru yo kurangiza amashuri',
      'fr': 'Vidéo de remise de diplôme',
      'sw': 'Video za mahafali',
      'ar': 'تصوير فيديو لحفلات التخرج',
    },
    'wedding_photography': {
      'rw': 'Gufotora ubukwe',
      'fr': 'Photographie de mariage',
      'sw': 'Upigaji picha wa harusi',
      'ar': 'تصوير حفلات الزفاف',
    },
    'wedding_videography': {
      'rw': 'Gufata amashusho y\'ubukwe',
      'fr': 'Vidéo de mariage',
      'sw': 'Video za harusi',
      'ar': 'تصوير فيديو لحفلات الزفاف',
    },
    'celebration_makeup': {
      'rw': 'Abasiga abantu mu birori',
      'fr': 'Maquillage pour les célébrations',
      'sw': 'Vipodozi vya sherehe',
      'ar': 'مكياج الاحتفالات',
    },
    'hair_styling': {
      'rw': 'Gutunganya imisatsi',
      'fr': 'Coiffure',
      'sw': 'Utengenezaji wa nywele',
      'ar': 'تصفيف الشعر',
    },
    'bridal_styling': {
      'rw': 'Gutegura imyambarire y\'abageni',
      'fr': 'Style de la mariée',
      'sw': 'Mitindo ya maharusi',
      'ar': 'تنسيق إطلالة العروس',
    },
    'dresses_bridesmaid_outfits': {
      'rw': 'Imyenda y\'ubukwe n\'iy\'abafasha umugeni',
      'fr': 'Robes de mariée et tenues des demoiselles d’honneur',
      'sw': 'Magauni ya harusi na mavazi ya wasaidizi',
      'ar': 'فساتين الزفاف وملابس وصيفات العروس',
    },
    'event_decoration': {
      'rw': 'Imitako y\'ibirori',
      'fr': 'Décoration événementielle',
      'sw': 'Mapambo ya matukio',
      'ar': 'ديكورات الفعاليات',
    },
    'celebration_catering': {
      'rw': 'Gutegura amafunguro y\'ibirori',
      'fr': 'Traiteur pour célébrations',
      'sw': 'Huduma za upishi wa sherehe',
      'ar': 'تموين الاحتفالات',
    },
    'celebration_cakes': {
      'rw': 'Ama-keke y\'ibirori',
      'fr': 'Gâteaux de célébration',
      'sw': 'Keki za sherehe',
      'ar': 'كعكات الاحتفالات',
    },
    'celebration_mc_dj': {
      'rw': 'Abayobora ibirori n\'aba-DJ',
      'fr': 'Maîtres de cérémonie et DJ',
      'sw': 'Watangazaji na ma-DJ',
      'ar': 'مقدمو الحفلات ومنسقو الموسيقى',
    },
    'celebration_singers_dancers': {
      'rw': 'Abaririmbyi n\'ababyinnyi',
      'fr': 'Chanteurs et danseurs',
      'sw': 'Waimbaji na wachezaji',
      'ar': 'مغنون وراقصون',
    },
    'wedding_event_planning': {
      'rw': 'Gutegura ibirori by\'ubukwe',
      'fr': 'Organisation de mariages',
      'sw': 'Mipango ya harusi',
      'ar': 'تنظيم حفلات الزفاف',
    },
    'event_transport': {
      'rw': 'Ubwikorezi bw\'ibirori',
      'fr': 'Transport événementiel',
      'sw': 'Usafiri wa matukio',
      'ar': 'النقل للفعاليات',
    },
    'engagement_planning': {
      'rw': 'Gutegura imihango yo gusaba',
      'fr': 'Organisation de fiançailles',
      'sw': 'Mipango ya uchumba',
      'ar': 'تنظيم الخطوبة',
    },
    'bridal_shower_planning': {
      'rw': 'Gutegura ibirori by\'umugeni',
      'fr': 'Organisation de fêtes prénuptiales',
      'sw': 'Mipango ya sherehe za maharusi',
      'ar': 'تنظيم حفلات ما قبل الزفاف',
    },
    'baby_shower_planning': {
      'rw': 'Gutegura ibirori byo kwitegura umwana',
      'fr': 'Organisation de fêtes prénatales',
      'sw': 'Mipango ya sherehe ya mtoto',
      'ar': 'تنظيم حفلات استقبال المولود',
    },
    'birthday_celebrations': {
      'rw': 'Ibirori by\'amavuko',
      'fr': 'Anniversaires',
      'sw': 'Sherehe za siku za kuzaliwa',
      'ar': 'حفلات أعياد الميلاد',
    },
    'anniversary_celebrations': {
      'rw': 'Ibirori byo kwizihiza isabukuru',
      'fr': 'Célébrations d’anniversaire',
      'sw': 'Sherehe za maadhimisho',
      'ar': 'احتفالات الذكرى السنوية',
    },
    'other_social_celebrations': {
      'rw': 'Ibindi birori by\'imiryango',
      'fr': 'Autres célébrations sociales',
      'sw': 'Sherehe nyingine za kijamii',
      'ar': 'احتفالات اجتماعية أخرى',
    },
  };

  static String? categoryName(String? localeCode, String slug) =>
      categoryNames[slug]?[localeCode?.toLowerCase()];

  static String? categoryDescription(String? localeCode, String slug) =>
      categoryDescriptions[slug]?[localeCode?.toLowerCase()];

  static String? capabilityName(String? localeCode, String slug) =>
      capabilityNames[slug]?[localeCode?.toLowerCase()];
}
