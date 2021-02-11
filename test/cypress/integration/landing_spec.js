/* global cy */
describe('The landing page', function () {
  it.skip ('should load ', function () {
    cy.visit('/exist/apps/airlock/index.html')
      .get('.alert')
      .contains('app.xql')
  })

})
