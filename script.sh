#!/bin/bash

# Renk kodları
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo " "
echo -e "${BLUE}########## RL-SWARM GÜNCELLEME BAŞLIYOR ##########${NC}"
echo " "

# Script temizliği
if [ -f "$HOME/script.sh" ]; then
  echo -e "${YELLOW}Önceki script.sh dosyası siliniyor...${NC}"
  rm -f "$HOME/script.sh"
fi

# Adımlar
BACKUP_DIR="$HOME/rl-swarm-backup"
RL_DIR="$HOME/rl-swarm"

# 1. Çalışan screen varsa durdur
if screen -list | grep -q "gensyn"; then
  echo -e "${YELLOW}Aktif 'gensyn' screen oturumu bulundu. Kapatılıyor...${NC}"
  screen -S gensyn -X stuff "^C"
  sleep 2
  screen -S gensyn -X quit
  echo -e "${GREEN}Screen kapatıldı.${NC}"
else
  echo -e "${RED}Aktif 'gensyn' screen oturumu bulunamadı.${NC}"
fi

# 2. Dosyaları yedekle
if [ -d "$RL_DIR" ]; then
  echo -e "${YELLOW}rl-swarm klasörü bulundu. Yedekleniyor...${NC}"
  mkdir -p "$BACKUP_DIR/modal-login"

  if [ -f "$RL_DIR/swarm.pem" ]; then
    cp "$RL_DIR/swarm.pem" "$BACKUP_DIR/swarm.pem"
    echo -e "${GREEN}swarm.pem yedeklendi.${NC}"
  else
    echo -e "${RED}swarm.pem bulunamadı, yedeklenemedi.${NC}"
  fi

  if [ -d "$RL_DIR/modal-login/temp-data" ]; then
    cp -r "$RL_DIR/modal-login/temp-data" "$BACKUP_DIR/modal-login/temp-data"
    echo -e "${GREEN}temp-data klasörü yedeklendi.${NC}"
  else
    echo -e "${RED}temp-data klasörü bulunamadı, yedeklenemedi.${NC}"
  fi

  echo -e "${YELLOW}rl-swarm klasörü siliniyor...${NC}"
  rm -rf "$RL_DIR"
else
  echo -e "${RED}rl-swarm klasörü bulunamadı, işlem iptal edildi.${NC}"
  exit 1
fi

# 3. Güncel repo klonlanıyor
echo -e "${GREEN}Güncel rl-swarm reposu klonlanıyor...${NC}"
git clone https://github.com/zunxbt/rl-swarm.git "$RL_DIR"

# 4. Yedekler geri yükleniyor
if [ -f "$BACKUP_DIR/swarm.pem" ]; then
  cp "$BACKUP_DIR/swarm.pem" "$RL_DIR/swarm.pem"
  echo -e "${GREEN}swarm.pem geri yüklendi.${NC}"
else
  echo -e "${RED}swarm.pem yedeği bulunamadı.${NC}"
fi

if [ -d "$BACKUP_DIR/modal-login/temp-data" ]; then
  mkdir -p "$RL_DIR/modal-login"
  cp -r "$BACKUP_DIR/modal-login/temp-data" "$RL_DIR/modal-login/temp-data"
  echo -e "${GREEN}temp-data klasörü geri yüklendi.${NC}"
else
  echo -e "${RED}temp-data klasörü yedeği bulunamadı.${NC}"
fi

# 5. Yarn işlemleri
echo -e "${GREEN}modal-login klasöründe yarn işlemleri yapılıyor...${NC}"
cd "$RL_DIR/modal-login"
yarn install
yarn upgrade
yarn add next@latest
yarn add viem@latest

# 6. testnet_grpo_runner.py dosyası düzenleniyor
echo -e "${GREEN}testnet_grpo_runner.py dosyası güncelleniyor...${NC}"
sed -i 's/dht = hivemind.DHT(start=True, \*\*self\._dht_kwargs(grpo_args))/dht = hivemind.DHT(start=True, ensure_bootstrap_success=False, \*\*self._dht_kwargs(grpo_args))/g' "$RL_DIR/hivemind_exp/runner/gensyn/testnet_grpo_runner.py"

# 7. Node'u yeniden başlat
echo -e "${GREEN}Yeni screen başlatılıyor ve node başlatılıyor...${NC}"
cd "$RL_DIR"
screen -dmS gensyn bash -c "python3 -m venv .venv && source .venv/bin/activate && ./run_rl_swarm.sh"

# 8. Bitiş
echo " "
echo -e "${GREEN}✅ Tüm işlemler tamamlandı, node yeniden başlatıldı.${NC}"
echo -e "${YELLOW}💡 Screen'e bağlanmak için: ${NC}screen -r gensyn"
echo " "
echo -e "${GREEN}#### Twitter : @Cryptoloss1 #####${NC}"
