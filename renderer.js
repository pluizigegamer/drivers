const { ipcRenderer } = require('electron')

const detectedList = document.getElementById('detectedList')
const dbList = document.getElementById('dbList')
const selectedList = document.getElementById('selectedList')
const search = document.getElementById('search')

// sample mock data for now
const sampleDB = [
  {name:'NVIDIA GeForce Driver',pattern:'NVIDIA',url:'https://www.nvidia.com/Download/index.aspx'} ,
  {name:'AMD Radeon Driver',pattern:'AMD',url:'https://www.amd.com/en/support'},
  {name:'Intel Graphics Driver',pattern:'Intel',url:'https://downloadcenter.intel.com/'}
]

function renderList(container, items){
  container.innerHTML = ''
  items.forEach((it, i)=>{
    const li = document.createElement('li')
    li.className='item'
    li.innerHTML = `<label><input type="checkbox" data-index="${i}"/> ${it.name}</label>`
    container.appendChild(li)
  })
}

renderList(dbList, sampleDB)

search.addEventListener('input', ()=>{
  const q = search.value.toLowerCase().trim()
  renderList(dbList, sampleDB.filter(d=>d.name.toLowerCase().includes(q) || d.pattern.toLowerCase().includes(q)))
})

// scan mock
document.getElementById('btnScan').addEventListener('click', ()=>{
  detectedList.innerHTML=''
  const devices = [{name:'NVIDIA GTX 1080',pattern:'NVIDIA'},{name:'Realtek Audio',pattern:'Audio'}]
  devices.forEach(d=>{
    const li = document.createElement('li')
    li.textContent = d.name
    detectedList.appendChild(li)
  })
})

// download selected
document.getElementById('btnDownload').addEventListener('click', ()=>{
  const checks = Array.from(dbList.querySelectorAll('input[type=checkbox]:checked'))
  const selected = checks.map(c=> sampleDB[parseInt(c.getAttribute('data-index'))])
  selectedList.innerHTML = ''
  selected.forEach(it=>{
    const li = document.createElement('li')
    li.textContent = it.name
    selectedList.appendChild(li)
    // open link in default browser
    const a = document.createElement('a')
    a.href = it.url
    a.target = '_blank'
    a.rel='noreferrer'
    document.body.appendChild(a)
    a.click()
    a.remove()
  })
})

document.getElementById('btnExit').addEventListener('click', ()=>{ window.close() })
