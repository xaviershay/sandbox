import React from 'react'

const makeIcon = (url, title, attribution) => {
  return {
    url,
    title,
    attribution,
  }
}

const icons = {
  duration: makeIcon(
    '/img/noun_Time_2027684.png',
    'Recipe Duration',
    'Time by Gagana from the Noun Project'
  ),
  craftingSpeed: makeIcon(
    '/img/noun_Time_2630876.png',
    'Crafting Speed',
    'Time by Alice Design from the Noun Project'
  ),
  productivityBonus: makeIcon(
    '/img/noun_Gear_3267680.png',
    'Productivity Bonus',
    'Gear by Vincencio from the Noun Project'
  ),
  targetRate: makeIcon(
    '/img/noun_Target_308.png',
    'Target Rate',
    'Target by Edward Boatman from the Noun Project'
  ),
  assemblersRequired: makeIcon(
    '/img/noun_counting_154887.png',
    'Assemblers Required',
    'counting by Magicon from the Noun Project'
  ),
}

const UIIcon = ({ name }) => {
  const icon = icons[name]

  if (!icon) throw new Error(`Unknown UI icon: ${name}`)

  return <img src={icon.url} width="20" height="20" alt={icon.title} />
}

export default UIIcon
