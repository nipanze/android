# Nipanze category discovery questions

## Purpose

Use these short prompts in the marketplace feed to teach people what they can
do on Nipanze. Each card should connect a familiar need to a clear next step:
find a provider or offer, compare available choices, or post a request and
receive responses.

The massage example should promise help finding and comparing listed prices,
not automatically tracking the cheapest price. Only describe price tracking
as an app capability if Nipanze adds that feature.

## How the cards are tailored

- **Start with a real situation.** Ask about a goal the user might recognize,
  rather than asking whether they are generally interested in a category.
- **Name the Nipanze action.** Say whether the user can find providers, browse
  requests, compare offers, or post a request.
- **Use the category context.** Show the prompt when its category is relevant
  to the user's location, recent activity, saved interests, or marketplace
  browsing.
- **Offer a low-pressure answer.** Use actions such as `Show me`, `Maybe later`,
  and `Not for me`. Avoid treating a skipped card as a negative preference.
- **Make the next step match the promise.** `Show me` should open that category
  with the relevant filter. A request-focused action should open the request
  form with the category selected. A comparison prompt must lead to actual
  comparable listings or clearly explain when there are no matches.
- **Save preferences only with consent.** A positive answer can offer to save
  the category so the feed can show more relevant listings. Let users edit or
  remove saved interests.
- **Keep sensitive topics respectful.** Health, finance, home care, and travel
  prompts should be optional, avoid assumptions, and never imply guaranteed
  outcomes or professional advice.

## Suggested questions by category

Each card uses a short, conversational question, one sentence about what
Nipanze can do, and two clear actions: browse existing requests or post a new
request with the category preselected.

| Category | Suggested question | What it teaches | `Show me` action |
| --- | --- | --- | --- |
| Machinery & Equipment | Need a tractor, generator, or other equipment for a job? Nipanze can help you find equipment to hire or buy. | Find equipment providers and products. | Browse machinery and equipment listings; offer `Post an equipment request`. |
| Transport & Logistics | Moving goods or need a delivery? Find transport providers on Nipanze or post the route and load you need moved. | Find transport or request a delivery. | Browse transport services; offer `Post a transport request`. |
| Specialized Products & Procurement | Looking for a hard-to-find product? Tell Nipanze what you need and find suppliers who can source it. | Source products locally or through procurement. | Browse suppliers or open a procurement request form. |
| Construction & Building | Planning a build or repair? Find contractors, tradespeople, or surveyors for the work. | Find construction professionals. | Browse construction services; offer `Post a project request`. |
| Business & Professional Services | Need help with legal work, accounting, HR, or consulting? Find a professional or post what your business needs. | Find or request business expertise. | Browse professional services; offer `Post a business request`. |
| Travel & International | Planning a trip or relocation? Request travel help on Nipanze and connect with providers who can assist. | Request travel, visa, flight, accommodation, or relocation support. | Open the travel request form with Travel & International selected. |
| Agriculture & Agribusiness | Need farm inputs, field services, or a buyer for produce? Find agricultural providers and opportunities. | Find farm support and agribusiness connections. | Browse agriculture listings; offer `Post a farm request`. |
| Pets & Animal Services | Need a vet, grooming, training, or boarding for your animal? Find local pet and animal care providers. | Find animal care services. | Browse pet services; offer `Post an animal care request`. |
| Energy & Water | Looking for solar power, backup electricity, a borehole, or water equipment? Find providers who can help. | Find energy and water solutions. | Browse energy and water services; offer `Post a project request`. |
| Technology & Digital | Need a website, app, IT support, or better security? Find a specialist or post your project. | Hire digital and IT expertise. | Browse technology services; offer `Post a project request`. |
| Marketing & Promotion | Want more people to discover your business? Find help with advertising, content, or promotion. | Find marketing services and creators. | Browse marketing services; offer `Post a campaign request`. |
| Education & Training | Looking for a course, tutor, internship, or professional training? Find opportunities and providers on Nipanze. | Find learning and career opportunities. | Browse education listings; offer `Post a training request`. |
| Events & Celebrations | Planning a wedding, party, or other event? Find caterers, equipment, venues, and event crews. | Assemble event services in one place. | Browse event providers; offer `Post an event request`. |
| Photo, Video, Music & Talent | Need a photographer, videographer, musician, or performer? Find creative talent for your project or event. | Hire creative professionals and performers. | Browse creative services; offer `Post a creative brief`. |
| Beauty, Fashion & Styling | Thinking about a massage or beauty appointment? Post what you need and compare service offers and prices from providers. | Request a personal care service and compare responses. | Browse beauty requests or post a request. Do not claim Nipanze tracks the cheapest price unless that capability exists. |
| Domestic & Household | Need help at home, childcare, cooking, or household care? Find providers or post the help you are looking for. | Find household support. | Browse household services; offer `Post a household request`. |
| Health & Medical | Looking for a clinic, medical provider, or specialist service? Find available providers and check their listed details. | Discover health providers. | Browse health listings. Do not imply diagnosis, treatment recommendations, or guaranteed availability. |
| Traditional & Cultural Services | Need help with a cultural ceremony or traditional service? Find providers who describe the services they offer. | Discover cultural services and providers. | Browse traditional and cultural services. |
| Finance & Investments | Exploring a loan or financing option? Browse available offers and compare the terms providers list. | Discover financing offers and compare stated terms. | Open loan offers; retain clear provider and eligibility details. |
| Property & Real Estate | Looking to rent, buy, lease, or find an agent? Browse property options and contact the listing provider. | Discover property listings and agents. | Browse property listings; offer `Post a property request`. |
| Investment Services | Looking for investment support? Find listed investment services and review each provider's details. | Discover investment service providers. | Browse investment services. Avoid promising returns or personalized financial advice. |
| Investment Opportunities | Building a startup or looking for investor connections? Find listed introductions and startup support. | Discover investment networks and support services. | Browse investment opportunities. Avoid implying funding is guaranteed. |
| Forex & Money Services | Need to exchange currency or send money? Find listed providers and compare their stated rates and fees. | Discover currency and money services. | Browse Forex and money services. Rates and availability must be current and verified. |
| Savings & Cooperatives | Interested in a SACCO, savings group, or cooperative? Find groups and review their membership information. | Discover savings groups and cooperatives. | Browse savings and cooperative listings. |

## Implemented answer and navigation behavior

1. Show a short question and one sentence explaining how Nipanze can help.
2. Offer two actions: browse existing requests for the category, or post a
   request with the category preselected. Put card controls and Saved interests
   in the menu to keep the card focused.
3. Never imply that offers, providers, the lowest price, or a response are
   guaranteed.
4. Store each view and action in `user_discovery_interactions`, keyed by user
   and template. Browse or Post suppresses that prompt for the user. Hide
   snoozes it for thirty days, Mute for a year, and a view alone for eighteen
   hours. This lets the feed move through categories without repeating an
   action the user has already taken.

## Rollout notes

- Keep category prompts in sync with the active `NeedCategory` catalog and the
  SQL seed/migration. When categories are added or retired, update all three.
- Keep question copy, answer options, category slug, browse destination, and
  request destination together in the discovery template configuration.
- Localize the prompt and buttons. Use plain language and local examples, but
  do not change the underlying category or destination when translating.
- Measure whether the user opened a listing, started a request, completed a
  request, or saved an interest. Do not treat a card tap alone as a successful
  match.
