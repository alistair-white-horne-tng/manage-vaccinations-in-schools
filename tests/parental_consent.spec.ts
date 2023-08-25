import { test, expect, Page } from "@playwright/test";

let p: Page;

test("Parental consent", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();
  await when_i_go_to_the_consent_start_page();
  await then_i_see_the_consent_start_page();

  await when_i_click_the_start_button();
  await then_i_see_the_edit_name_page();

  await when_i_enter_the_childs_name();
  await and_i_click_continue();
  await then_i_see_the_date_of_birth_page();

  await when_i_enter_the_childs_date_of_birth();
  await and_i_click_continue();
  await then_i_see_the_consent_confirm_page();

  await when_i_click_the_confirm_button();
  // Temporary until we have a better "kthxbai" page
  await then_i_see_the_start_page();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function when_i_go_to_the_consent_start_page() {
  await p.goto("/sessions/1/consents/start");
}

async function when_i_click_the_start_button() {
  await p.getByRole("button", { name: "Start now" }).click();
}

async function when_i_click_the_confirm_button() {
  await p.getByRole("button", { name: "Confirm" }).click();
}

async function when_i_enter_the_childs_name() {
  await p.getByLabel("First name").fill("Joe");
  await p.getByLabel("Last name").fill("Test");
  await p.getByText("Yes").click();
  await p.getByLabel("Known as").fill("LittleJoeTests");
}

async function when_i_enter_the_childs_date_of_birth() {
  await p.getByLabel("Day").fill("01");
  await p.getByLabel("Month").fill("01");
  await p.getByLabel("Year").fill("2010");
}

async function and_i_click_continue() {
  await p.getByRole("button", { name: "Continue" }).click();
}

async function then_i_see_the_consent_start_page() {
  await expect(p.locator("h1")).toContainText(
    "Give or refuse consent for a flu vaccination",
  );
}

async function then_i_see_the_consent_confirm_page() {
  await expect(p.locator("h1")).toContainText("Check and confirm answers");
}

async function then_i_see_the_start_page() {
  await expect(p.locator("h1")).toContainText(
    "Manage vaccinations for school-aged children",
  );
}

async function then_i_see_the_edit_name_page() {
  await expect(p.locator("h1")).toContainText("What is your child’s name?");
}

async function then_i_see_the_date_of_birth_page() {
  await expect(p.locator("h1")).toContainText(
    "What is your child’s date of birth?",
  );
}
