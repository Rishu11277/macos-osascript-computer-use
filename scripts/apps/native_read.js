// Output row count is bounded; collection retrieval may enumerate all records.
// Shared JXA implementation. All parameters are data; no eval.
function run(argv) {
 var mode=argv[0], limit=Number(argv[1]||20), query=argv[2]||'';
 var names={notes:'Notes',mail:'Mail',calendar:'Calendar',reminders:'Reminders',finder:'Finder',messages:'Messages'};
 if (!Number.isInteger(limit)||limit<1||limit>100) throw Error('Limit must be 1..100');
 if (mode==='system') {
  var sa=Application.currentApplication(); sa.includeStandardAdditions=true;
  var se=Application('System Events');
  return JSON.stringify({volume:sa.getVolumeSettings(),darkMode:se.appearancePreferences.darkMode()});
 }
 var app=Application(names[mode]);
 if (!app.running()) throw Error(names[mode]+' is not running; launch it intentionally before reading');
 function safe(fn) {try {var v=fn(); return v===undefined?null:v;}catch(e){return null;}}
 var rows=[];
 if(mode==='notes') {
  var items=app.notes();
  for(var i=0;i<items.length&&rows.length<limit;i++) {
   var n=items[i],title=n.name();
   if(!query||title.toLowerCase().indexOf(query.toLowerCase())>=0) rows.push({id:n.id(),name:title});
  }
 } else if(mode==='mail') {
  var items=app.inbox.messages();
  for(var i=0;i<Math.min(items.length,limit);i++){var m=items[i];rows.push({id:m.id(),subject:m.subject(),sender:m.sender(),read:m.readStatus()});}
 } else if(mode==='calendar') {
  var items=app.calendars();
  for(var i=0;i<Math.min(items.length,limit);i++){var c=items[i];rows.push({name:c.name(),writable:c.writable()});}
 } else if(mode==='reminders') {
  var items=app.lists();
  for(var i=0;i<Math.min(items.length,limit);i++){var l=items[i];rows.push({id:l.id(),name:l.name()});}
 } else if(mode==='finder') {
  var items=app.selection();
  for(var i=0;i<Math.min(items.length,limit);i++){var f=items[i];rows.push({name:f.name(),url:safe(function(){return f.url();})});}
 } else if(mode==='messages') {
  var items=app.chats();
  for(var i=0;i<Math.min(items.length,limit);i++){var c=items[i];rows.push({id:c.id(),name:safe(function(){return c.name();})});}
 }
 return JSON.stringify(rows);
}
