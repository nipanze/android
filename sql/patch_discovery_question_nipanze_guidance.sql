begin;

update public.discovery_question_templates as template
set
  title = patch.title,
  question = patch.question,
  cta_label = patch.cta_label,
  updated_at = now()
from (
  values
    (
      'travel_planning_basic',
      'Plan a trip with Nipanze',
      'Use Nipanze to request travel services or help planning your trip, then connect with providers who can assist.',
      'Get travel help'
    ),
    (
      'internship_interest_basic',
      'Explore career opportunities',
      'Browse internships and career development requests, then contact the people offering opportunities that interest you.',
      'Browse career opportunities'
    ),
    (
      'business_equipment_basic',
      'Find business support',
      'Browse equipment, transport, procurement, and business services people offer. Use the + button to post what your business needs.',
      'Find business services'
    ),
    (
      'financial_interest_basic',
      'Explore finance options',
      'Compare loan offers or find people to exchange currency with on Nipanze.',
      'Explore finance options'
    )
) as patch(slug, title, question, cta_label)
where template.slug = patch.slug;

commit;
