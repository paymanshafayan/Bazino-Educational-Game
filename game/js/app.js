/* ═══════════════════════════════════════════════════
   BAZINO — app.js · Spiele-Engine / بازی انجین
═══════════════════════════════════════════════════ */
const $=s=>document.querySelector(s);
const $$=s=>document.querySelectorAll(s);
const KEY="bazino_v1";

let S=null;          /* save state */
let LANG="tr";       /* ui language */
let R=null;          /* active round */
let EX=null;         /* active exam */
let AC=null;         /* audio ctx */

/* ────────── helpers ────────── */
const t=k=>(STR[LANG]&&STR[LANG][k])||STR.tr[k]||k;
const tf=(k,o)=>Object.keys(o||{}).reduce((s,p)=>s.split("{"+p+"}").join(o[p]),t(k));
const esc=s=>String(s).replace(/[&<>"]/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"}[c]));
const shuffle=a=>a.map(v=>[Math.random(),v]).sort((x,y)=>x[0]-y[0]).map(v=>v[1]);
const pickL=(o,l)=>(l==="fa"?o.f:l==="en"?o.e:o.t)||o.t;
const show=id=>{$$(".screen").forEach(s=>s.classList.remove("active"));$(id).classList.add("active");window.scrollTo(0,0);};
function toast(m,ms=2600){const el=$("#toast");el.textContent=m;el.classList.remove("hidden");clearTimeout(el._x);el._x=setTimeout(()=>el.classList.add("hidden"),ms);}
function beep(f,d=0.12,type="sine"){if(!S||!S.sound)return;try{AC=AC||new(window.AudioContext||window.webkitAudioContext)();const o=AC.createOscillator(),g=AC.createGain();o.type=type;o.frequency.value=f;g.gain.setValueAtTime(.15,AC.currentTime);g.gain.exponentialRampToValueAtTime(.001,AC.currentTime+d);o.connect(g);g.connect(AC.destination);o.start();o.stop(AC.currentTime+d);}catch(e){}}

/* ────────── save / level / achievements ────────── */
const save=()=>{S.lang=LANG;localStorage.setItem(KEY,JSON.stringify(S));};
const load=()=>{try{return JSON.parse(localStorage.getItem(KEY));}catch(e){return null;}};
const lvlOf=xp=>LEVEL_XP.reduce((n,t)=>xp>=t?n+1:n,0);
const lvlPct=xp=>{const L=lvlOf(xp);if(L>=LEVEL_XP.length)return 100;const a=LEVEL_XP[L-1],b=LEVEL_XP[L];return Math.round((xp-a)/(b-a)*100);};
const toNext=xp=>{const L=lvlOf(xp);return L>=LEVEL_XP.length?0:LEVEL_XP[L]-xp;};
const cleared=()=>REGIONS.filter(r=>(S.regions[r.id]||{rounds:0}).rounds>0).length;
const bossOpen=()=>cleared()>=4&&lvlOf(S.xp)>=4;

function grant(id){
  if(S.ach[id])return;
  S.ach[id]=true;save();
  toast(tf("newAch",{n:t(aTrans(id))}),3000);
  beep(880,.18,"triangle");
}
/* achievement i18n key mapping */
function aTrans(id){const m={first:"achFirst",seri:"achSeri",perf:"achPerf",dil:"achDil",fatih:"achFatih",snav:"achSnav",sv5:"achSv5",gold:"achGold"};return m[id]||id;}

function applyRewards(xp,co){
  const l0=lvlOf(S.xp);
  S.xp+=xp;S.coins+=co;S.lifeCoins+=co;
  if(S.dil>=10)grant("dil");
  if(S.lifeCoins>=200)grant("gold");
  const l1=lvlOf(S.xp);
  let msg=[];
  if(l1>l0){msg.push(tf("lvlUp",{n:l1}));beep(660,.1);setTimeout(()=>beep(990,.15),120);
    if(l1>=5)grant("sv5");
    REGIONS.forEach(rg=>{if(rg.needLevel>l0&&rg.needLevel<=l1)msg.push(tf("unlock",{n:pickL(rg.name,LANG)}));});
  }
  save();renderHud();
  if(msg.length)setTimeout(()=>toast(msg.join("  ·  "),4200),600);
}

/* ────────── language ────────── */
function setLang(l){LANG=l;document.documentElement.lang=l;document.documentElement.dir=(l==="fa")?"rtl":"ltr";if(S)save();}

/* ══════════════ WELCOME ══════════════ */
function renderWelcome(){
  const langs=[["tr","Türkçe"],["en","English"],["fa","فارسی"]];
  $("#w-langs").innerHTML=langs.map(([c,n])=>`<button data-l="${c}" class="${c===LANG?"on":""}">${n}</button>`).join("");
  $$("#w-langs button").forEach(b=>b.onclick=()=>{setLang(b.dataset.l);renderWelcome();});
  $("#w-tag").textContent=t("tag");$("#w-note").textContent=t("tip");
  $("#w-name").placeholder=t("name");
  const sel=$("#w-age");const cur=sel.value||(S?S.age:14);
  sel.innerHTML=`<option value="" disabled>${t("age")}</option>`+[12,13,14,15,16,17,18].map(a=>`<option value="${a}" ${+cur===a?"selected":""}>${a}</option>`).join("");
  const updLeague=()=>{const a=+sel.value||0;const L=LEAGUES[ageLeague(a)];$("#w-league").innerHTML=a?`${t("leagueIs")} <b>${L.emoji} ${t(L.id)}</b> (${L.min}–${L.max})`:"";};
  sel.onchange=updLeague;updLeague();
  if(S){$("#w-name").value=S.name;$("#w-continue").classList.remove("hidden");$("#w-continue").textContent=`${t("cont")} (${S.name})`;$("#w-start").textContent=t("reset");}
  else{$("#w-continue").classList.add("hidden");$("#w-start").textContent=t("start");}
  $("#w-continue").onclick=()=>{renderMap();show("#scr-map");};
  $("#w-start").onclick=()=>{
    const nm=$("#w-name").value.trim()||"Oyuncu";
    const ag=+sel.value||(S?S.age:14);
    if(S&&!confirm(tf("resetC")))return;
    S={name:nm,age:ag,league:ageLeague(ag),xp:0,coins:0,lifeCoins:0,dil:0,sound:true,bestExam:-1,regions:{},ach:{},seenHint:false};
    save();renderMap();show("#scr-map");toast(tf("done",{n:nm}));
  };
  show("#scr-welcome");
}
const ageLeague=a=>a<=14?0:a<=16?1:2;

/* ══════════════ HUD + MAP ══════════════ */
function renderHud(){
  $("#h-name").textContent=S.name;
  const L=LEAGUES[S.league];
  $("#h-league").textContent=`${L.emoji} ${t(L.id)} · ${S.age}`;
  $("#h-xp").textContent=S.xp;$("#h-coin").textContent=S.coins;$("#h-lvl").textContent=lvlOf(S.xp);
  $("#h-lvlwrap").title=tf("toNext",{n:toNext(S.xp)});
  $("#h-xpfill").style.width=lvlPct(S.xp)+"%";
}
function regionUnlocked(rg){return lvlOf(S.xp)>=rg.needLevel;}
function poolOf(id){return Q.filter(q=>q.region===id&&q.lev<=S.league);}

function renderMap(){
  renderHud();
  $("#m-title").textContent=t("mapT");
  $("#m-regions").innerHTML=REGIONS.map(rg=>{
    const st=S.regions[rg.id]||{rounds:0};
    const open=regionUnlocked(rg);
    return `<div class="region-card ${rg.cls} ${open?"":"locked"}" data-id="${rg.id}">
      <span class="${open?"star":"lock"}">${open?(st.rounds>=3?"⭐":""):"🔒"}</span>
      <div class="big">${rg.emoji}</div>
      <div class="city">${pickL(rg.city,LANG)}</div>
      <div class="name">${pickL(rg.name,LANG)}</div>
      <div class="prog">${open?tf("rounds",{n:st.rounds}):tf("locked",{n:rg.needLevel})}</div>
    </div>`;}).join("");
  $$("#m-regions .region-card").forEach(c=>c.onclick=()=>{
    const rg=REGIONS.find(x=>x.id===c.dataset.id);
    if(!regionUnlocked(rg)){toast(tf("locked",{n:rg.needLevel}));return;}
    openRegion(rg);
  });
  const b=$("#m-boss"),open=bossOpen();
  b.className="boss-card"+(open?"":" locked");
  b.innerHTML=`<div class="big">🎓</div><h3>${t("bossN")}</h3>
    <p>${open?t("bossD"):t("bossLock")}</p>
    ${S.bestExam>=0?`<span class="best">${tf("best",{n:S.bestExam})}</span>`:""}`;
  b.onclick=()=>{if(!bossOpen()){toast(t("need4"));return;}openExamIntro();};
  $("#m-hint").innerHTML=t("hint");
  $("#h-achBtn").onclick=showAch;
  $("#h-setBtn").onclick=showSettings;
}

/* ══════════════ REGION SCREEN ══════════════ */
function openRegion(rg){
  const st=S.regions[rg.id]||{rounds:0};
  const n=Math.min(8,poolOf(rg.id).length);
  $("#r-card").innerHTML=`<div class="big">${rg.emoji}</div>
    <h2>${pickL(rg.name,LANG)}</h2>
    <p class="sub">${pickL(rg.city,LANG)} · ${tf("rounds",{n:st.rounds})}</p>
    <p>${tf("rDesc",{n})}</p>
    <div class="btn-row">
      <button class="btn primary big" id="r-go">${t("go")}</button>
      <button class="btn ghost" id="r-back">${t("back")}</button>
    </div>`;
  $("#r-go").onclick=()=>startRound(rg.id);
  $("#r-back").onclick=()=>{renderMap();show("#scr-map");};
  show("#scr-region");
}

/* ══════════════ QUIZ ENGINE ══════════════ */
function startRound(regionId){
  const qs=shuffle(poolOf(regionId)).slice(0,8);
  R={region:regionId,qs,i:0,hearts:3,streak:0,best:0,correct:0,xp:0,coins:0,dilFlags:{},prevLvl:lvlOf(S.xp)};
  $("#q-quit").onclick=()=>{renderMap();show("#scr-map");};
  renderQ();show("#scr-quiz");
}
const dilEligible=()=>["math","science"].includes(R.region);
const qLang=()=>{const base=LANG;return R&&dilEligible()&&R.dilFlags[R.i]?"en":base;};

function renderQ(){
  const q=R.qs[R.i],L=qLang(),Lg=(L==="fa"?"f":L==="en"?"e":"t");
  $("#q-topic").textContent=q.topic[L==="fa"?2:L==="en"?1:0];
  $("#q-count").textContent=tf("qOf",{a:R.i+1,b:R.qs.length});
  $("#q-hearts").textContent="❤️".repeat(R.hearts)+"🖤".repeat(3-R.hearts);
  $("#q-streak").textContent=R.streak>=2?`🔥 ${R.streak}`:"";
  $("#q-text").textContent=L==="fa"?q.qf:L==="en"?q.qe:q.qt;
  /* Dil bonusu düğmesi */
  const db=$("#q-dil");
  if(dilEligible()){
    db.classList.remove("hidden");
    db.textContent=R.dilFlags[R.i]?t("dilOn"):t("dil");
    db.onclick=()=>{R.dilFlags[R.i]=!R.dilFlags[R.i];if(LANG==="en")R.dilFlags[R.i]=true;renderQ();};
  } else db.classList.add("hidden");
  $("#q-fb").classList.add("hidden");
  const box=$("#q-opts");box.innerHTML="";
  q.o[Lg].forEach((txt,idx)=>{
    const b=document.createElement("button");b.className="opt";
    b.innerHTML=`<span class="key">${"ABCD"[idx]}</span><span>${esc(txt)}</span>`;
    b.onclick=()=>answerQ(idx,b);box.appendChild(b);
  });
}

function answerQ(idx,btn){
  const q=R.qs[R.i];
  $$("#q-opts .opt").forEach((b,j)=>{b.classList.add("disabled");if(j===q.ans)b.classList.add("correct");});
  const dil=dilEligible()&&(LANG==="en"||R.dilFlags[R.i]);
  const ok=idx===q.ans;
  let headCls="good",headTxt=t("correct");
  if(ok){
    R.correct++;R.streak++;R.best=Math.max(R.best,R.streak);
    let xp=10+(R.streak>=5?5:R.streak>=3?2:0);
    if(dil){xp=Math.round(xp*1.1);S.dil++;}
    R.xp+=xp;R.coins+=5;beep(660,.1);
    if(!S.ach.first)grant("first");
    if(R.streak>=5)grant("seri");
  }else{
    btn.classList.add("wrong");R.streak=0;R.hearts--;headCls="bad";headTxt=t("wrong");beep(180,.18,"square");
  }
  $("#q-hearts").textContent="❤️".repeat(Math.max(0,R.hearts))+"🖤".repeat(3-Math.max(0,R.hearts));
  $("#q-streak").textContent=R.streak>=2?`🔥 ${R.streak}`:"";
  const L=qLang();
  $("#q-fbhead").className="fb-head "+headCls;$("#q-fbhead").textContent=headTxt;
  $("#q-why").textContent=L==="fa"?q.wf:L==="en"?q.we:q.wt;
  $("#q-next").textContent=R.hearts<=0?"…":t("next");
  $("#q-fb").classList.remove("hidden");
  $("#q-next").onclick=()=>{
    R.i++;
    if(R.hearts<=0)return endRound(false);
    if(R.i>=R.qs.length)return endRound(true);
    renderQ();
  };
}

function endRound(won){
  const total=R.qs.length;
  const acc=Math.round(R.correct/total*100);
  const perfect=won&&R.correct===total;
  if(perfect){R.coins+=10;grant("perf");}
  if(won){
    S.regions[R.region]=S.regions[R.region]||{rounds:0};
    S.regions[R.region].rounds++;
    if(S.regions[R.region].rounds>=3)grant("fatih");
  }
  applyRewards(R.xp,R.coins);
  renderResult({won,title:won?t("resW"):t("resL"),
    emoji:perfect?"🌟":won?(acc>=60?"🎉":"👍"):"💪",
    rows:[[t("acc"),`<b>${acc}%</b> (${R.correct}/${total})`],[t("xpg"),`<b>+${R.xp} ⭐</b>`],[t("cg"),`<b>+${R.coins} 🪙</b>`]],
    extra:perfect?t("perfect"):!won?t("failNoHp"):"",
    region:R.region});
}

function renderResult(cfg){
  $("#res-card").innerHTML=`
    <div class="res-emoji">${cfg.emoji}</div>
    <h2>${cfg.title}</h2>
    ${cfg.score!=null?`<div class="res-score ${cfg.score>=60?"good":"bad"}">${cfg.score}%</div>`:""}
    ${cfg.rows.map(([k,v])=>`<div class="stat-row"><span>${k}</span><span>${v}</span></div>`).join("")}
    ${cfg.extra?`<div class="ach-pop">${cfg.extra}</div>`:""}
    <div class="btn-row">
      ${cfg.region?`<button class="btn primary" id="res-retry">${t("retry")}</button>`:""}
      ${cfg.goExam?`<button class="btn primary" id="res-exam">${t("playA")}</button>`:""}
      <button class="btn ghost" id="res-map">${t("back")}</button>
    </div>`;
  if(cfg.region)$("#res-retry").onclick=()=>startRound(cfg.region);
  if(cfg.goExam)$("#res-exam").onclick=openExamIntro;
  $("#res-map").onclick=()=>{renderMap();show("#scr-map");};
  show("#scr-result");
}

/* ══════════════ EXAM (BOSS) ══════════════ */
function openExamIntro(){
  $("#ex-intro").classList.remove("hidden");$("#ex-live").classList.add("hidden");
  $("#ex-intro").innerHTML=`<div class="big">🎓</div><h2>${t("exT")}</h2><p style="margin:12px 0 18px">${t("exP")}</p>
    <div class="btn-row"><button class="btn primary big" id="ex-go">${t("exGo")}</button>
    <button class="btn ghost" id="ex-back">${t("back")}</button></div>`;
  $("#ex-go").onclick=startExam;$("#ex-back").onclick=()=>{renderMap();show("#scr-map");};
  show("#scr-exam");
}
function startExam(){
  const pool=shuffle(Q.filter(q=>q.lev<=S.league&&q.region!=="zeka"));
  EX={qs:pool.slice(0,10),i:0,correct:0,left:480,sitting:1};
  $("#ex-intro").classList.add("hidden");$("#ex-live").classList.remove("hidden");
  $("#ex-quit").onclick=()=>{clearInterval(EX.tm);renderMap();show("#scr-map");};
  toast(t("exS1"));
  EX.tm=setInterval(()=>{EX.left--;const m=String(Math.floor(EX.left/60)).padStart(2,"0"),s=String(EX.left%60).padStart(2,"0");
    $("#ex-timer").textContent=`${m}:${s}`;if(EX.left<=0){clearInterval(EX.tm);finishExam();}},1000);
  renderExQ();
}
function renderExQ(){
  const q=EX.qs[EX.i],Lg=LANG==="fa"?"f":LANG==="en"?"e":"t";
  $("#ex-count").textContent=tf("qOf",{a:EX.i+1,b:EX.qs.length})+(EX.sitting===2?` · ${t("exS2")}`:"");
  $("#ex-text").textContent=LANG==="fa"?q.qf:LANG==="en"?q.qe:q.qt;
  $("#ex-fb").classList.add("hidden");
  const box=$("#ex-opts");box.innerHTML="";
  q.o[Lg].forEach((txt,idx)=>{
    const b=document.createElement("button");b.className="opt";
    b.innerHTML=`<span class="key">${"ABCD"[idx]}</span><span>${esc(txt)}</span>`;
    b.onclick=()=>answerEx(idx,b);box.appendChild(b);
  });
}
function answerEx(idx,btn){
  const q=EX.qs[EX.i];
  $$("#ex-opts .opt").forEach((b,j)=>{b.classList.add("disabled");if(j===q.ans)b.classList.add("correct");});
  const ok=idx===q.ans;if(ok){EX.correct++;beep(660,.08);}else{btn.classList.add("wrong");beep(180,.15,"square");}
  $("#ex-fbhead").className="fb-head "+(ok?"good":"bad");$("#ex-fbhead").textContent=ok?t("correct"):t("wrong");
  $("#ex-fb").classList.remove("hidden");
  $("#ex-next").onclick=()=>{
    EX.i++;
    if(EX.i===5){toast(t("exBreak"));EX.sitting=2;setTimeout(()=>toast(t("exS2")),1500);renderExQ();return;}
    if(EX.i>=EX.qs.length){clearInterval(EX.tm);finishExam();return;}
    renderExQ();
  };
}
function finishExam(){
  const pct=Math.round(EX.correct/EX.qs.length*100);
  const pass=pct>=60;
  if(pct>(S.bestExam||-1))S.bestExam=pct;
  if(pass)grant("snav");
  const xp=EX.correct*12+(pass?20:0),co=EX.correct*5+(pass?30:0);
  applyRewards(xp,co);
  renderResult({won:pass,title:pass?t("pass"):t("fail"),score:pct,
    emoji:pass?"🎓":"😅",rows:[[t("acc"),`<b>${pct}%</b> (${EX.correct}/${EX.qs.length})`],[t("xpg"),`<b>+${xp} ⭐</b>`],[t("cg"),`<b>+${co} 🪙</b>`]],
    extra:"",goExam:true});
}

/* ══════════════ MODALS: achievements / settings ══════════════ */
function openModal(html){$("#modalCard").innerHTML=html;$("#modalBack").classList.remove("hidden");
  $("#modalBack").onclick=e=>{if(e.target.id==="modalBack")closeModal();};}
const closeModal=()=>$("#modalBack").classList.add("hidden");
function showAch(){
  openModal(`<h2 style="text-align:center;margin-bottom:10px">${t("achT")} 🏆</h2>`+
    ACH.map(a=>{const got=!!S.ach[a.id];
      return`<div class="ach-item ${got?"":"locked"}"><div class="em">${got?a.emoji:"🔒"}</div>
        <div><div class="t1">${t(aTrans(a.id))}</div><div class="t2">${t(aTrans(a.id)+"D")}</div></div></div>`;}).join("")+
    `<div class="btn-row"><button class="btn primary" onclick="closeModal()">${t("close")}</button></div>`);
}
function showSettings(){
  openModal(`<h2 style="text-align:center;margin-bottom:12px">${t("setT")} ⚙️</h2>
    <div class="stat-row"><span>${t("lang")}</span><span class="set-row">
      <button class="btn tiny ${LANG==="tr"?"primary":"ghost"}" onclick="setLang2('tr')">TR</button>
      <button class="btn tiny ${LANG==="en"?"primary":"ghost"}" onclick="setLang2('en')">EN</button>
      <button class="btn tiny ${LANG==="fa"?"primary":"ghost"}" onclick="setLang2('fa')">FA</button></span></div>
    <div class="stat-row"><span>🔊</span><button class="btn tiny ghost" id="sndBtn">${t(S.sound?"sndOn":"sndOff")}</button></div>
    <div class="btn-row">
      <button class="btn ghost" id="rstBtn">${t("reset")}</button>
      <button class="btn primary" onclick="closeModal()">${t("close")}</button></div>`);
  $("#sndBtn").onclick=()=>{S.sound=!S.sound;save();$("#sndBtn").textContent=t(S.sound?"sndOn":"sndOff");};
  $("#rstBtn").onclick=()=>{if(confirm(t("resetC"))){localStorage.removeItem(KEY);location.reload();}};
}
window.setLang2=l=>{setLang(l);closeModal();renderMap();show("#scr-map");};

/* ══════════════ BOOT ══════════════ */
(function boot(){
  const saved=load();
  if(saved){S=saved;setLang(saved.lang||"tr");}
  setLang(S?S.lang:LANG);
  renderWelcome();
})();
