extends RefCounted


const CHAPTERS := {
	1: {
		"title": "O primeiro\nédito",
		"body": "Vire a carta e guarde o número.\n\nQuando ela desaparecer, ande essa quantidade de casas.",
		"art": "color_first_edict",
	},
	2: {
		"title": "Dois éditos",
		"body": "Vire as duas cartas e guarde os números.\n\nMova-se livremente para escolher a posição inicial. Confirme com Enter ou pelo botão; só então os éditos começam.\n\nAnde o valor da carta esquerda e, depois, o da direita, terminando na casa iluminada. Não há cronômetro.",
		"art": "color_two_edicts",
	},
	3: {
		"title": "As torres",
		"body": "As torres atacam em linha reta.\n\nO número acima de cada torre indica quantas casas ela anda. A quantidade é a mesma na linha e na coluna.\n\nObserve onde vão chegar antes de confirmar sua posição. O primeiro par avança e ataca antes do primeiro édito.",
		"art": "color_rooks",
	},
	4: {
		"title": "A ordem\ndos pares",
		"body": "As flechas indicam o próximo par.\n\nEscape do primeiro ataque na posição inicial e do segundo após o édito esquerdo. Pare à distância do refúgio indicada pelo édito direito.\n\nDepois siga até lá. A casa iluminada só protege no final.",
		"art": "color_attack_order",
	},
	5: {
		"title": "Os bispos",
		"body": "Os bispos atacam pelas diagonais: casas da mesma cor, em caminhos que se cruzam como um X.\n\nEscape do primeiro par na posição inicial e do segundo ao terminar o édito esquerdo.\n\nApós os dois ataques, cumpra o édito direito até a casa iluminada.",
		"art": "color_bishops",
	},
	6: {
		"title": "A balança",
		"body": "Agora, os números das cartas são pesos.\n\nObserve as cartas e os pratos da balança. Você tem cinco segundos para se mover antes de o tabuleiro se inclinar.\n\nPode andar livremente. Não há uma casa iluminada nesta prova.\n\nQual lado pesa mais? Para onde o tabuleiro pode inclinar?",
		"art": "color_balance",
	},
	7: {
		"title": "Chaotic",
		"label": "SIMULAÇÃO",
		"body": "A simulação aprimora os poderes da Rainha.\n\nResolva as subtrações ou divisões: esquerda, depois direita. As cartas queimam em cinco segundos.\n\nEm 10 segundos, escolha a posição do primeiro ataque. Use o édito esquerdo para escapar do segundo; o direito, para chegar ao refúgio. Os éditos não têm cronômetro.",
		"art": "color_chaotic",
	},
}


static func chapter(number: int) -> Dictionary:
	return CHAPTERS.get(number, {})
