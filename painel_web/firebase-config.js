// Configuração do Firebase
const firebaseConfig = {
  apiKey: "AIzaSyCK58XBPxi7Bc2iaxKwwYlaMHf1R8T85Ek",
  authDomain: "gerenciamento-de-cacambas.firebaseapp.com",
  projectId: "gerenciamento-de-cacambas",
  storageBucket: "gerenciamento-de-cacambas.firebasestorage.app",
  messagingSenderId: "972154992772",
  appId: "1:972154992772:web:7535d4b6ed240a766caad1"
};

// Inicializa o Firebase no escopo global
firebase.initializeApp(firebaseConfig);
const auth = firebase.auth();

// Inicializações seguras para evitar falhas se os scripts do Firestore/Storage não forem carregados na página
const db = typeof firebase.firestore === 'function' ? firebase.firestore() : null;
const storage = typeof firebase.storage === 'function' ? firebase.storage() : null;

// Função global para migrar qualquer documento sem admin_id para o primeiro administrador que logar
async function migrarDocumentosSemAdminId(userUid) {
  if (!db) return;
  const key = `migrado_${userUid}`;
  if (localStorage.getItem(key)) return; // Evita executar repetidamente desnecessariamente
  
  const colecoes = ['clientes', 'cacambas', 'motoristas', 'locacoes', 'despesas', 'caminhoes'];
  for (const col of colecoes) {
    try {
      const snap = await db.collection(col).get();
      const promises = [];
      snap.forEach(doc => {
        const data = doc.data();
        if (!data.hasOwnProperty('admin_id')) {
          promises.push(db.collection(col).doc(doc.id).update({ admin_id: userUid }));
        }
      });
      if (promises.length > 0) {
        await Promise.all(promises);
      }
    } catch (e) {
      console.error(`Erro ao migrar coleção ${col}:`, e);
    }
  }
  localStorage.setItem(key, 'true');
}
