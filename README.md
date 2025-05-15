# Desafio técnico e-commerce

API de e-commerce.

## Como executar

1. Certifique-se de ter o Docker instalado e configurado;
2. Se estiver usando Docker 20.10.0 ou superior e, portanto, tiver acesso ao [Docker Compose V2](https://docs.docker.com/compose/releases/migrate/), execute `docker compose up web` no seu terminal. Caso contrário, execute `docker-compose up web`;
3. Acesse as rotas da API em `localhost:3000`.

## Como executar os testes

1. Certifique-se de ter o Docker instalado e configurado;
2. Se estiver usando Docker 20.10.0 ou superior e, portanto, tiver acesso ao [Docker Compose V2](https://docs.docker.com/compose/releases/migrate/), execute `docker compose up test` no seu terminal. Caso contrário, execute `docker-compose up test`;

## Como acessar a Web UI do Sidekiq

1. Execute a aplicação (ver acima);
2. Acesse `localhost:3000/sidekiq`.

## Documentação da API

### GET /cart

Exibe dados atuais do carrinho.

#### Regras

1. A ID de um carrinho existente deve estar salva como `cart_id` da sessão atual.

#### Exemplo de resposta

```json
{
  "id": 1,
  "products": [
    {
      "id": 1,
      "name": "Samsung Galaxy S24 Ultra",
      "quantity": 1,
      "unit_price": "12999.99",
      "total_price": "12999.99"
    }
  ],
  "total_price": "12999.99"
}
```

### POST /cart

Cria carrinho e/ou adiciona produtos a ele.

#### Regras

1. `product_id` deve ser a ID de um produto existente;
2. `quantity` deve ser um número inteiro positivo.

**Ao acessar esta rota, caso não haja uma `cart_id` registrada na sessão atual, um novo carrinho será criado e sua ID será registrada na sessão.**

#### Exemplo de payload

```json
{
  "product_id": 1,
  "quantity": 1
}
```

#### Exemplo de resposta

```json
{
  "id": 1,
  "products": [
    {
      "id": 1,
      "name": "Samsung Galaxy S24 Ultra",
      "quantity": 1,
      "unit_price": "12999.99",
      "total_price": "12999.99"
    }
  ],
  "total_price": "12999.99"
}
```

### POST /cart/add_item

Adiciona produtos a carrinho existente.

#### Regras

1. A ID de um carrinho existente deve estar salva como `cart_id` da sessão atual;
2. `product_id` deve ser a ID de um produto existente;
3. `quantity` deve ser um número inteiro positivo.

#### Exemplo de payload

```json
{
  "product_id": 1,
  "quantity": 1
}
```

#### Exemplo de resposta

```json
{
  "id": 1,
  "products": [
    {
      "id": 1,
      "name": "Samsung Galaxy S24 Ultra",
      "quantity": 2,
      "unit_price": "12999.99",
      "total_price": "25999,98"
    }
  ],
  "total_price": "25999,98"
}
```

### DELETE /cart/:product_id

Remove produtos de carrinho existente.

#### Regras

1. A ID de um carrinho existente deve estar salva como `cart_id` da sessão atual;
2. `product_id` deve ser a ID de um produto existente no carrinho.

#### Exemplo de resposta

```json
{
  "id": 1,
  "products": [],
  "total_price": "0.0"
}
```

## Observações

Apesar das orientações recebidas indicarem que os testes preexistentes não devem ser editados, foi necessário pular um teste em `spec/requests/carts_spec.rb`, pois:

1. Ele faz um POST para `/cart/add_items`, mas as orientações solicitam a criação de um _endpoint_ `/cart/add_item`;
2. Como teste de _request_, ele não permite a manipulação de dados de sessão; logo, não é possível descobrir a qual carrinho os itens devem ser adicionados.

Para garantir o funcionamento das rotas, criei testes de _controller_ - que permitem a manipulação de dados de sessão - em `spec/controllers/carts_controller_spec.rb`
