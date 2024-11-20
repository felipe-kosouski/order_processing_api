# Order Processing API

### Descrição

A Order Processing API é um serviço que permite a leitura, validação e processamento de arquivos contendo ordens de compra. A API suporta:

* Upload de arquivos em formato txt para processamento em lote.
* Consulta de ordens com filtros por `order_id` e `date_range`.
* Paginação e metadados nos resultados.
* Resiliência contra duplicatas durante a importação.

### Índice

1. [Requisitos](#requisitos)
2. [Instalação](#instalação)
   * [Sem Docker](#sem-docker)
   * [Com Docker](#com-docker)
3. [Configuração](#configuração)
4. [Uso](#uso)
   * [Endpoints](#endpoints)
   * [Filtros](#filtros)
   * [Paginação](#paginação)
5. [Arquitetura](#arquitetura)
   * [Fluxo de upload de arquivos](#fluxo-de-upload-de-arquivos)
   * [Fluxo de consulta de ordens](#fluxo-de-consulta-de-ordens)
6. [Decisões e Aprendizados](#decisões-e-aprendizados)
7. [Testes](#testes)
8. [Monitoramento](#monitoramento)
9. [Melhorias futuras](#melhorias-futuras)

### Requisitos
* Ruby 3.x
* Rails 7.x
* SQLite 3.x
* Redis
* Sidekiq
* Docker (opcional)
* Datadog (opcional)

### Instalação

#### Sem Docker
1. Clone o repositório
```bash
git clone https://github.com/felipe-kosouski/order-processing-api.git
cd order-processing-api
```

2. Instale as dependências
```bash
bundle install
```

3. Crie o banco de dados
```bash
rails db:create db:migrate
```

4. Inicie o servidor
```bash
rails s
```

#### Com Docker
1. Clone o repositório
```bash
git clone https://github.com/felipe-kosouski/order-processing-api.git
cd order-processing-api
```

2. Construa a imagem
```bash
docker compose build
```

3. Rode as migrações
```bash
docker compose run --rm web rails db:create db:migrate
```

4. Inicie o servidor
```bash
docker compose up
```

### Configuração
Utilizando Docker, é necessario apenas informar a variável `DD_API_KEY` no arquivo `docker-compose.yml`

Caso não utilize Docker, crie um arquivo `.env` na raiz do projeto com as seguintes variáveis:
```bash
RAILS_ENV
REDIS_URL
DD_API_KEY
DD_SITE
DD_ENV
DD_SERVICE
DD_VERSION
DD_LOGS_ENABLED
DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL
```

Caso esteja rodando sem Docker, certifique-se de que o Redis e Sidekiq estejam rodando e configurado corretamente.
```bash
redis-server
bundle exec sidekiq
```

### Uso

#### Endpoints

1. Upload de arquivos
* **Endpoint**: `POST /orders/upload`
* **Descrição**: Faz o upload de um arquivo txt contendo ordens de compra.
* **Parâmetros**: `file` (obrigatório): Arquivo no formato .txt.

#### Exemplo de requisição
```bash
curl -X POST -F "file=@/path/to/file.txt" http://localhost:3000/orders/upload
```
#### Exemplo de resposta
```json
{
  "message": "File processed successfully",
  "total_lines": 3352,
  "batch_count": 3
}
```

2. Consulta de ordens
* **Endpoint**: `GET /orders`
* **Descrição**: Consulta as ordens de compra.
* **Parâmetros**:
  * `order_id` (opcional): ID da ordem de compra. 
  * `start_date` (opcional): Data de inicio no formato `YYYY-MM-DD`. 
  * `end_date` (opcional): Data de fim no formato `YYYY-MM-DD`. 
  * `page` (opcional): Número da página. 
  * `per_page` (opcional): Quantidade de registros por página.

#### Exemplo de requisição
```bash
curl -X GET "http://localhost:3000/orders?order_id=123&page=1&per_page=10"
```

#### Exemplo de resposta
```json
[
   {
      "user_id": 1,
      "name": "User1",
      "orders": [
         {
            "order_id": 123,
            "total": "100.5",
            "date": "2024-11-20",
            "products": [
               {
                  "product_id": 456,
                  "value": "100.5"
               }
            ]
         }
      ]
   }
]
```

#### Filtros
* `order_id` (opcional): ID da ordem de compra.
* `start_date` (opcional): Data de inicio no formato `YYYY-MM-DD`.
* `end_date` (opcional): Data de fim no formato `YYYY-MM-DD`. Case um end date não seja fornecido a data final será a data atual.

#### Paginação
* `page` (opcional): Número da página.
* `per_page` (opcional): Quantidade de registros por página.

Os metadados de paginação são retornados no header da resposta.
```http
link: <http://localhost:3000/orders?page=2&per_page=10>; rel="next",
      <http://localhost:3000/orders?page=1&per_page=10>; rel="first",
      <http://localhost:3000/orders?page=2&per_page=10>; rel="last"
current-page: 1
page-items: 10
total-pages: 10
total-count: 100
```

### Arquitetura
A API foi desenvolvida utilizando o framework Rails, com uma arquitetura baseada em serviços. A aplicação é dividida nas seguintes camadas:
* **Controllers**: Responsáveis por receber as requisições HTTP, chamar os serviços necessários, serializar e paginar dados.
* **Services**: Responsável primariamente pela lógica de leitura e processamento de arquivos.
* **Models**: Model de Order. Representa a entidade de ordem de compra.
* **Jobs**: Responsável por processar a inserção de ordens de compra em background.

#### Fluxo de upload de arquivos
1. O usuário faz uma requisição para o endpoint de upload de arquivos.
2. O controller chama o `FileProcessorService`, que é responsável por:
   * Ler o arquivo em streaming 
   * Dividir os dados em batches de no maximo 1000 registros
   * Enfileirar os batches para processamento em background chamando o `ProcessOrderBatchInsertJob`
3. O `ProcessOrderBatchInsertJob` é responsável por:
   * Processar o batch de ordens de compra
   * Inserir as ordens de compra no banco de dados
   * Em caso de duplicatas, um erro é lançado e apenas as ordens únicas são inseridas
   * Em caso de erro, feito uma busca por duplicatas e apenas as ordens únicas são inseridas através de um retry dentro do próprio job.

#### Fluxo de consulta de ordens
1. O usuário faz uma requisição para o endpoint de consulta de ordens.
2. O controller chama o `OrderFilter`, que irá filtrar as ordens de acordo com os parâmetros fornecidos.
3. Os resultados são então paginados, agrupados por user, serializados e devolvidos ao usuário.

### Decisões e Aprendizados

#### Linguagem e Framework
* A utilização do Ruby on Rails foi uma escolha natural para o desenvolvimento da API, devido a sua facilidade de uso, quantidade de ferramentas disponíveis e familiaridade do autor com a ferramenta. 

#### Arquitetura baseada em service object
* Com relação à arquitetura, a escolha por serviços foi feita para manter a aplicação modular e facilitar a manutenção e testes. 

#### Processamento em background
* A utilização de jobs em background foi feita para garantir a escalabilidade da aplicação e evitar timeouts em requisições longas.

#### Estrutura de dados
* Sobre o modelo de dados, tinha inicialmente sido pensada para suportar diferentes tabelas relacionadas, compondo a informação final. Porém, durante o desenvolvimento, notou-se que, tendo a API como objetivo principal fazer o processamento de arquivos para inserção de dados e posteriormente sua consulta, a estrutura de dados poderia ser simplificada para uma única tabela de `Orders`. Fazendo com que a API seja mais simples e eficiente.
Foram também adicionados indices para melhorar a performance de consultas e ajudar com a verificação de duplicatas.

#### Banco de dados
* A escolha do SQLite foi feita para facilitar o desenvolvimento e testes, sendo que o SQLite é um banco de dados leve e fácil de configurar.
Nos últimos anos o SQLite tem se tornado uma opção viável para aplicações de pequeno e médio porte. Se assumirmos que essa API não terá inicialmente um grande volume de dados, o SQLite é uma escolha aceitável para o propósito da aplicação, principalmente levando em consideração o fator custo, já que não necessita de um servidor de banco de dados dedicado.
* Durante o desenvolvimento, foi possível encontrar algumas limitações, principalmente ao utilizar batches combinados com background jobs. O SQLite suporta apenas uma conexão por vez, o que pode causar problemas de concorrência, deixando a aplicação bastante lenta. Para contornar esse problema, foi necessário adicionar um lock para garantir que apenas um job seja executado por vez.
* Apesar dessas limitações, foi optado por ainda assim manter o SQLite, com o principal objetivo de ver até onde seria possível chegar com o banco de dados padrão do Rails.
* A maneira como a aplicação foi desenvolvida permite a fácil troca do banco de dados, bastando apenas adicionar a gem do banco de dados desejado, rodar as migrações. E caso queira, é possível editar o arquivo `sidekiq.yml` para aumentar o número de jobs que podem ser processados simultaneamente.
* Ainda assim, é importante ressaltar que, para um volume de dados maior, seria necessário migrar para um banco de dados mais robusto, como o PostgreSQL.

### Testes
Os testes foram escritos utilizando RSpec e podem ser rodados com o comando `rspec`.
```bash
bundle exec rspec
```

### Segurança
A aplicação foi desenvolvida com segurança em mente, utilizando boas práticas de segurança, como:
* Utilização da Gem Brakeman para identificar possíveis vulnerabilidades.
* Utilização da gem Rack::Attack para proteção contra ataques de força bruta.

Cobertura inclui:
* Testes de unidade para models e serviços
* Testes de integracão para endpoints
* Testes de cenário para manuseio de duplicatas e erros.

Após rodar os testes, o arquivo de coverage pode ser encontrado em `coverage/index.html`.

### Monitoramento
A aplicação está configurada para enviar logs e métricas para o Datadog.
Caso queira visualizar logs e métricas:

1.	Certifique-se de que o Datadog Agent está rodando.
2.	Configure as variáveis de ambiente (ex.: DD_API_KEY).
3.	Acesse o painel Datadog para visualizar métricas.

### Melhorias futuras
* Adicionar autenticação e autorização.
* Services podem ser refatorados para serem ainda mais modulares.
* Melhorias na performance de consultas utilizando cache.
* Adicionar mais cenários de teste.
* Adicionar mais métricas e logs.
* Adicionar maior flexibilidade para consultas com mais filtros.
* Adicionar suporte a novos formatos de arquivo.
* Deploy automático utilizando CI/CD e containers.

